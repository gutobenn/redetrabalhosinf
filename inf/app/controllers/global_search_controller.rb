class GlobalSearchController < ApplicationController

	MAX_PROJECTS = 7
	# MAX_COURSES = 21
	MAX_PEOPLE = 14

	def index
		@projects = []
	    @courses = []
	    @people = []

	    if params[:gq] and !params[:gq].empty?
	    	@hasQuery = true
	    	@query = params[:gq]

	    	@projects = Project.scoped
		    @courses = Course.scoped
		    @people = Person.scoped

			@projects = @projects.search(@query)
			@totalProjects = @projects.size
			@projects.sort_by!{|p| p.relevance }.reverse!
			@projects = @projects[0..MAX_PROJECTS-1]

			@courses = @courses.search(@query).order("name DESC")
			@totalCourses = @courses.size
			# @courses = @courses.limit(MAX_COURSES)

			@people = @people.search(@query).order("created_at DESC")
			@totalPeople = @people.size
			@people = @people.limit(MAX_PEOPLE)

			@numResults = @totalProjects + @totalCourses + @totalPeople
	    else
	    	@numResults = @totalProjects = @totalCourses = @totalPeople = 0
	    	@hasQuery = false
	    	@query = ""
	    end

	end	 

end
