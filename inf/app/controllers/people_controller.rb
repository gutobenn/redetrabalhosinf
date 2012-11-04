class PeopleController < ApplicationController
  # GET /people
  def index
    if params[:search]
      @people = Person.search(params[:search])
    else
      @people = Person.all
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /people/1
  def show
    # It's called ID because of the default routing, but we use this parameter with the user's NICK. See routes.rb for more info.
    if params[:id]
      search = Person.where(nick: params[:id])

      if(search.empty?)
        redirect_to root_path, alert: "Nao consegui encontrar #{params[:id]}."
      else
        @person = search.first
      end
    end
  end

  # GET /people/new
  def new
    @person = Person.new
  end

  # GET /people/1/edit
  def edit
    @person = Person.find(params[:id])
    if not @person.barra.nil?
      @barra = @person.barra.split("/")
    else
      @barra = ["",""]
    end

  end

  # POST /people
  def create
    p = params[:person];

    @person = Person.new(name: p["name"], email: p["email"])

    respond_to do |format|
      if @person.save
        format.html { redirect_to @person, notice: 'Perfil criado com sucesso.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  # PUT /people/1
  def update
    @person = Person.find(params[:id])
    p = params[:person]
    barra = params["barra1"] + "/" + params["barra2"]

    respond_to do |format|
      if @person.update_attributes(name: p["name"], about: p["about"], personal_link: p["personal_link"], barra: barra )
        format.html { redirect_to profile_path(@person.nick), notice: 'Perfil atualizado com sucesso.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /people/1
  def destroy
    @person = Person.find(params[:id])
    @person.destroy
  end
end
