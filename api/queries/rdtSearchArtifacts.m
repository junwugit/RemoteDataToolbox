%%% RemoteDataToolbox Copyright (c) 2015 The RemoteDataToolbox Team.
%
% Search an Archiva Maven repository with fuzzy matching of free text.
%   @param searchText free text of search terms to match
%   @param remotePath optional remote path to restrict search
%   @param artifactId optional artifactId to restrict search
%   @param version optional artifact version to restrict search
%   @param type optional artifact type to restrict search
%   @param configuration optional RemoteDataToolbox configuration struct
%
% @details
% Searches an Archiva Maven repository for artifacts matching the search
% terms in the given @a searchText.  @a configuration.serverUrl should
% point to the Archiva server root.
%
% @details
% By default, searches for any artifact that matches the given @a
% searchText.  If @a remotePath, @a artifactId, @a version, or @a type is
% provided the search will be restricted to only those artifacts that match
% the given restriction.
%
% @details
% Returns a struct array describing artifacts that matched the given @a
% searchText, or else [] if the query failed.
%
% @details
% Usage:
%   artifacts = rdtSearchArtifacts(searchText, remotePath, artifactId, version, type, configuration)
%
% @ingroup queries
function artifacts = rdtSearchArtifacts(searchText, remotePath, artifactId, version, type, configuration)

artifacts = [];

if nargin < 1 || isempty(searchText)
    searchText = '';
end

if nargin < 2 || isempty(remotePath)
    remotePath = '';
end

if nargin < 3 || isempty(artifactId)
    artifactId = '';
end

if nargin < 4 || isempty(version)
    version = '';
end

if nargin < 5 || isempty(type)
    type = '';
end

if nargin < 6 || isempty(configuration)
    configuration = rdtConfiguration();
else
    configuration = rdtConfiguration(configuration);
end

%% Query the Archiva server with fuzzy matching on searchText.
resourcePath = '/restServices/archivaServices/searchService/quickSearch';
query.queryString = searchText;
response = rdtRequestWeb(resourcePath, query, [], configuration);
if isempty(response)
    return;
end

nArtifacts = numel(response);
artifactCell = cell(1, nArtifacts);
for ii = 1:nArtifacts
    r =response{ii};
    r.remotePath = r.groupId;
    artifactCell{ii} = rdtArtifact(r);
end
artifacts = [artifactCell{:}];

%% Filter results for given restrictions.
% Would prefer to let the server do the filtering as part of the query,
% instead of transferring extra results and doing filtering here on the
% client side.  But in testing, the Archiva searchArtifacts resource didn't
% allow this.
isMatch = isFieldMatch(artifacts, 'remotePath', remotePath) ...
    & isFieldMatch(artifacts, 'artifactId', artifactId) ...
    & isFieldMatch(artifacts, 'version', version) ...
    & isFieldMatch(artifacts, 'type', type);
artifacts = artifacts(isMatch);

%% True where each element has given field equal to given string.
function isMatch = isFieldMatch(structArray, fieldName, fieldString)
nElements = numel(structArray);
isMatch = true(1, nElements);

% default "all elements match"
if isempty(fieldString)
    return;
end

% check each element explicitly
for ii = 1:nElements
    isMatch(ii) = strcmp(fieldString, structArray(ii).(fieldName));
end
