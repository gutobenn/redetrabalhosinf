# -*- encoding : utf-8 -*-
require 'will_paginate/array'

class ProjectsController < ApplicationController

	before_filter :checkLogged, :only => [:edit, :update, :destroy, :new, :create, :like, :unlike]

	def processTags(tags)
		tagTexts = []
		# Check if one of the entered Tags doesn't exist on the Database.
		# This is how select2 taggin mode works: it will give us the a number if the recognizes
		#   that the tag entered already exists, otherwise it will give us the string of the new tag.
		tags.size.times do |i|
			
			if not is_number?(tags[i])
				tagTexts << tags[i]
				# Make sure this tag doesn't already exist.
				duplicates = Tag.where(tag_text: tags[i])
				if duplicates.empty?
					newTag = Tag.create(tag_text: tags[i])
					tags[i] = newTag.id
				else
					tags[i] = duplicates.first.id
				end
			else
				tagTexts << Tag.find(tags[i]).tag_text
			end
		end

		return tagTexts
	end

	# GET /projects
	def index
		# if params[:id]
  #     		search = Person.where(nick: params[:id])
  #     		if search.empty?
  #       		not_found
  #       	else
  #       		@projects = search.first.projects
  #       	end
  #       else
			@projects = Project.scoped
		# end

		@projects = @projects.includes(:people)

		handleProjectsParams()

		@projects = @projects.all

		# Handle sorting
		handleProjectsSorting @projects, params[:sort], params[:direction]
		
		# Do pagination
		@projects = @projects.paginate(per_page: PROJECTS_PER_PAGE, page: params[:page])

		# Handle view modes (default is LIST)
		@viewMode = :list
		if params[:view]=="list"
			@viewMode = :list
		elsif params[:view]=="thumbs"
			@viewMode = :thumbs
		end

		# @lastSort = params[:sort]

		respond_to do |format|
			format.html
			format.js
		end
	end

	# GET /projects/1
	def show

		# Test if we're doing it github style
		# if params[:person] && params[:project]
		#   user = Person.find_by_nick(params[:person])
		#   @project = user.projects.includes(:comments).find_by_title(params[:project]) if user
		# else
			@project = Project.includes(:comments).find(params[:id])

		not_found if @project.nil?

		@project.update_attribute :viewCount, @project.viewCount+1
	end

	def myProjects
		# It's called ID because of the default routing, but we use this parameter with the user's NICK.
		if user_signed_in?
			@person = current_user.person
			@projects = @person.projects

			handleProjectsParams()

			@projects = @projects.all

			# Handle sortings
			handleProjectsSorting @projects, params[:sort], params[:direction]

			# Do pagination
			@projects = @projects.paginate(per_page: PROJECTS_PER_PAGE, page: params[:page])

			# Default view is LIST
			@viewMode = (!params[:view] or params[:view].empty? or params[:view]=="list") ? :list : :thumbs

			respond_to do |format|
				format.html
				format.js
			end
		end
	end

	# GET /projects/new
	def new
		@project = Project.new

		@project.links.build

	end

	# GET /projects/1/edit
	def edit
		@project = Project.find(params[:id])

		checkAuthorization(@project)

	end

	# POST /projects
	def create
		pp = params["project"]
		owner = current_user.person
		
		tags = params["tag_tokens"].split(",")
		tags_str = processTags(tags).join(" ")

		people = params["people"].split(',')
		if not people.include?(current_user.person.id.to_s)
			people.push(current_user.person.id)
		end

		# Save!
		pp["tag_ids"] = tags
		pp["person_ids"] = people
		pp["likeCount"] = 0
		pp["tags_str"] = tags_str
		@project = Project.new(pp)

		respond_to do |format|
			if @project.save
				@project.create_activity :create, owner: current_user
				@project.people.each do |p|
					if p.user!=current_user
						@project.create_activity :addOwnership, owner: current_user, recipient: p.user
					end
				end

				if params[:commit]=="save_and_add_new"
					format.html { redirect_to new_project_url, notice: 'Trabalho <b>' + @project.title + '</b> criado com sucesso.' }
				else
					format.html { redirect_to project_path(@project), notice: 'Adicionar trabalho criado com sucesso.' }
				end
			else
				format.html { render action: "new" }
			end
		end

	end

	def is_number?(object)
		Float(object) != nil rescue false
	end

	# PUT /projects/1
	def update
		@project = Project.find(params["id"])

		checkAuthorization(@project)
		isAdminEditing = (current_user.admin? and not @project.people.include?(current_user.person))

		pp = params[:project]
		
		tags = params["tag_tokens"].split(',')
		tags_str = processTags(tags).join(" ")

		people = params["people"].split(',')
		if not people.include?(current_user.person.id.to_s) and not isAdminEditing
			people.push(current_user.person.id)
		end
		oldAuthors = @project.people.dup

		

		success = true
		if params["deleteImage"] == "1"
			success = @project.update_attributes(image: nil)
		elsif pp["image"]
			success = @project.update_attributes(image: pp["image"])
		end

		if params["deleteFile"] == "1"
			success &&= @project.update_attributes(file: nil, downloadCount: 0)
		elsif pp["file"]
			success &&= @project.update_attributes(file: pp["file"], downloadCount: 0)
		end

		if pp["link"]!=@project.link
			@project.update_attributes(link: pp["link"], linkHitCount: 0)
		end
		
		
		# Save!
		pp["tag_ids"] = tags
		pp["person_ids"] = people
		pp["tags_str"] = tags_str
		success &&= @project.update_attributes(pp) 


		respond_to do |format|
			if success
				if not isAdminEditing
					if not params["hiddenUpdate"]
						@project.create_activity :update, owner: current_user
					end

					# Check if there were new authors included in project's authorship
					@project.people.each do |p|
						if not oldAuthors.include?(p)
							@project.create_activity :addOwnership, owner: current_user, recipient: p.user
						end
					end

					# Check if there were authors removed from project's authorship
					oldAuthors.each do |p|
						if not @project.people.include?(p)
							@project.create_activity :removeOwnership, owner: current_user, recipient: p.user

							# Remove this project from the person's favorites projects list
							if p.favorites.include?(@project)
								p.favorites.delete(@project)
							end
						end
					end
				end

				if params[:commit]=="save_and_add_new"
					format.html { redirect_to new_project_url, notice: 'Trabalho atualizado com sucesso.' }
				else
					format.html { redirect_to project_path(@project), notice: 'Trabalho atualizado com sucesso.' }
				end
			else
				format.html { render action: "edit" }
			end
		end
	end

	# DELETE /projects/1
	def destroy
		@project = Project.find(params[:id])
		title = @project.title
		@project.destroy

		respond_to do |format|
			format.html { redirect_to projects_url, notice: 'Trabalho <b>' + title + '</b> exluído com sucesso.' }
			format.js
		end
	end

	def like
		@project = Project.find(params[:id])
		if @project
			@person = current_user.person
			if not @project.likes.include?(@person)
				@project.create_activity :like, owner: current_user
				@project.likes.push(@person)
				@project.update_attributes(likeCount: @project.likeCount+1)
			end
		end

		respond_to do |format|
			format.js
		end
	end

	def unlike
		@project = Project.find(params[:id])
		if @project
			@person = current_user.person
			if @project.likes.include?(@person)
				# Finds and deletes the notification of this like
				PublicActivity::Activity.where(owner_id: current_user, trackable_id: @project.id, key: "project.like").destroy_all

				@project.likes.delete(@person)
				@project.update_attributes(likeCount: @project.likeCount-1)
			end
		end
		
		respond_to do |format|
			format.js
		end
	end

	def favorite
		@project = Project.find(params[:id])
		if @project
			@person = current_user.person
			if @project.isAuthoredByUser?(current_user)
				if not @person.favorites.include?(@project)
					# add favorite project
					@person.favorites.push(@project)
				else
					# remove favorite project
					@person.favorites.delete(@project)
				end
			end
		end

		respond_to do |format|
			format.js
		end
	end

	def downloadFile
		@project = Project.find(params[:id])

		if cookies["#{@project.id}_downloaded"]==nil
			@project.update_attribute :downloadCount, @project.downloadCount+1
			cookies["#{@project.id}_downloaded"] = true
		end

		respond_to do |format|
			format.html { redirect_to @project.file.url }
		end
	end

	def clickLink
		@project = Project.find(params[:id])

		if cookies["#{@project.id}_clicked"]==nil
			@project.update_attribute :linkHitCount, @project.linkHitCount+1
			cookies["#{@project.id}_clicked"] = true     
		end

		respond_to do |format|
			format.html { redirect_to @project.link }
		end
	end

end
