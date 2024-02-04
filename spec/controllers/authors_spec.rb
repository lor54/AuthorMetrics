# spec/controllers/authors_controller_spec.rb

require 'rails_helper'

RSpec.describe AuthorsController, type: :controller do
    describe 'GET #index' do
        it 'renders the index template' do
            get :index
            expect(response).to render_template('index')
        end

        context 'with valid parameters' do
            let(:author_name) { 'Leonardo' }

            it 'assigns authors and other instance variables' do
                get :index, params: { name: author_name, page: 1 }
                expect(assigns(:authors)).to be_an_instance_of(Array)
                expect(assigns(:pages)).to be_an_instance_of(Integer)
            end

            it 'renders the index template' do
                get :index, params: { name: author_name, page: 1 }
                expect(response).to render_template('index')
            end
        end
    end

    describe 'GET #show' do
        let(:author_id) { '354/9339' }

        it 'renders the show template' do
            get :show, params: { id: author_id }
            expect(response).to render_template('show')
        end

        context 'with valid parameters' do
            it 'assigns author and other instance variables' do
                get :show, params: { id: author_id }
                expect(assigns(:author)).to be_an_instance_of(Hash)
            end

            it 'renders the show template' do
                get :show, params: { id: author_id }
                expect(response).to render_template('show')
            end
        end

        context 'with collaborations tab' do
            it 'assigns collaborations and other instance variables' do
                get :show, params: { id: author_id, tab: 'collaborations' }
                expect(assigns(:collaborations)).to be_an_instance_of(Hash)
            end
        end

        context 'with invalid type parameter' do
            it 'sets type to "all"' do
                get :show, params: { id: author_id, type: 'invalid_type' }
                expect(assigns(:type)).to eq('all')
            end
        end
    end
end
