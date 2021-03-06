# frozen_string_literal: true

require_relative 'spec_helper'
require 'openapi_first/operation'

RSpec.describe OpenapiFirst::Operation do
  let(:spec) { OpenapiFirst.load('./spec/data/parameters.yaml') }

  describe '#parameters_json_schema' do
    let(:schema) do
      described_class.new(spec.operations.first).parameters_json_schema
    end

    let(:expected_schema) do
      {
        'type' => 'object',
        'required' => %w[
          term
        ],
        'properties' => {
          'birthdate' => {
            'format' => 'date',
            'type' => 'string'
          },
          'filter' => {
            'type' => 'object',
            'required' => ['tag'],
            'properties' => {
              'tag' => {
                'type' => 'string'
              },
              'other' => {
                'type' => 'object'
              }
            }
          },
          'include' => {
            'type' => 'string',
            'pattern' => '(parents|children)+(,(parents|children))*'
          },
          'limit' => {
            'type' => 'integer',
            'format' => 'int32'
          },
          'term' => {
            'type' => 'string'
          }
        }
      }
    end

    it 'returns the JSON Schema for the request' do
      expect(schema).to eq expected_schema
    end

    describe 'with flat named nested[params]' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters-flat.yaml') }

      let(:expected_schema) do
        {
          'type' => 'object',
          'required' => %w[term filter],
          'properties' => {
            'birthdate' => {
              'format' => 'date',
              'type' => 'string'
            },
            'filter' => {
              'type' => 'object',
              'required' => %w[tag id],
              'properties' => {
                'tag' => {
                  'type' => 'string'
                },
                'id' => {
                  'type' => 'integer'
                },
                'other' => {
                  'type' => 'string'
                }
              }
            },
            'include' => {
              'type' => 'string',
              'pattern' => '(parents|children)+(,(parents|children))*'
            },
            'limit' => {
              'type' => 'integer',
              'format' => 'int32'
            },
            'term' => {
              'type' => 'string'
            }
          }
        }
      end

      it 'converts it to a nested schema' do
        expect(schema).to eq expected_schema
      end
    end
  end

  describe '#response_schema_for' do
    let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }
    let(:operation) { spec.operations.first }

    it 'finds the matching response schema for a response' do
      schema = operation.response_schema_for(200, 'application/json')
      expect(schema['title']).to eq 'Pets'
    end

    describe 'when status code cannot be found' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters.yaml') }
      let(:operation) { spec.operations.last }

      it 'raises an exception' do
        expected_msg =
          "Response status code or default not found: 201 for 'GET /info'"
        expect do
          operation.response_schema_for(201, 'application/json')
        end.to raise_error OpenapiFirst::ResponseCodeNotFoundError, expected_msg
      end
    end

    describe 'when response object media type cannot be found' do
      it 'raises an exception' do
        expected_msg =
          "Response media type found: 'application/xml' for 'GET /pets'"
        expect do
          operation.response_schema_for(200, 'application/xml')
        end.to raise_error OpenapiFirst::ResponseMediaTypeNotFoundError,
                           expected_msg
      end
    end

    describe 'when response content is not defined' do
      before do
        expect(operation).to receive(:response_for).with(200) do
          { 'description' => 'Blank' }
        end
      end

      it 'returns nil' do
        schema = operation.response_schema_for(200, 'application/json')
        expect(schema).to be_nil
      end
    end

    describe 'when response object media type is not defined' do
      before do
        expect(operation).to receive(:response_for).with(200) do
          { 'content' => {} }
        end
      end

      it 'returns nil' do
        schema = operation.response_schema_for(200, 'application/json')
        expect(schema).to be_nil
      end
    end

    describe 'when response content schema is not defined' do
      before do
        expect(operation).to receive(:response_for).with(200) do
          { 'content' => { 'application/json' => {} } }
        end
      end

      it 'returns nil' do
        schema = operation.response_schema_for(200, 'application/json')
        expect(schema).to be_nil
      end
    end
  end

  describe '#response_for' do
    let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }
    let(:operation) { spec.operations.first }

    it 'finds the matching response object for a status code' do
      response = operation.response_for(200)
      expect(response).to be_a Hash
      description = response['description']
      expect(description).to eq 'A paged array of pets'
    end

    describe 'when status code cannot be found' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters.yaml') }
      let(:operation) { spec.operations.last }

      it 'raises an exception' do
        expected_msg =
          "Response status code or default not found: 201 for 'GET /info'"
        expect do
          operation.response_for(201)
        end.to raise_error OpenapiFirst::ResponseCodeNotFoundError, expected_msg
      end
    end
  end

  describe '#content_type_for' do
    it 'finds the response content type for a request' do
      operation = spec.operations.first
      content_type = operation.content_type_for(200)
      expect(content_type).to eq 'application/json'
    end

    describe 'when status code cannot be found' do
      it 'raises an exception' do
        operation = spec.operations[1]
        expected_msg =
          "Response status code or default not found: 201 for 'GET /info'"
        expect do
          operation.content_type_for(201)
        end.to raise_error OpenapiFirst::ResponseCodeNotFoundError, expected_msg
      end
    end
  end
end
