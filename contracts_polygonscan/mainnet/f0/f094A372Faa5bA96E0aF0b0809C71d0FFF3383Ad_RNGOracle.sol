// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./VRFConsumerBase.sol";

interface Caller {
	function randomCallback(bytes32 _queryId, bytes32 _randomData) external;
	function modulusCallback(bytes32 _queryId, uint256 _resolution, uint256 _result) external;
	function seriesCallback(bytes32 _queryId, uint256 _resolution, uint256[] calldata _results) external;
	function queryFailed(bytes32 _queryId) external;
}

contract RNGOracle is VRFConsumerBase {

	uint256 constant private UINT256_MAX = type(uint256).max;
	uint256 constant private FLOAT_SCALAR = 2**64;

	enum RequestType {
		RANDOM,
		MODULUS,
		SERIES
	}

	struct RequestInfo {
		bytes32 seed;
		Caller caller;
		uint32 placedBlockNumber;
		RequestType requestType;
		uint32 requestIndex;
	}
	mapping(bytes32 => RequestInfo) private requestMap;

	struct ModulusInfo {
		uint256 modulus;
		uint256 betmask;
	}
	ModulusInfo[] private modulusInfo;

	struct SeriesInfo {
		uint128 seriesIndex;
		uint128 runs;
	}
	SeriesInfo[] private seriesInfo;

	struct Series {
		uint256 sum;
		uint256 maxRuns;
		uint256[] series;
		uint256[] cumulativeSum;
		uint256[] resolutions;
	}
	Series[] private series;

	bytes32 internal keyHash;
	uint256 internal fee;


	constructor() VRFConsumerBase(0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 0xb0897686c545045aFc77CF20eC7A532E3120E0F1) {
		keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
		fee = 1e14;
	}

	function createSeries(uint256[] memory _newSeries) public returns (uint256 seriesIndex) {
		require(_newSeries.length > 0);

		uint256 _sum = 0;
		uint256 _zeros = 0;
		uint256 _length = _newSeries.length;
		uint256[] memory _cumulativeSum = new uint256[](_length);
		for (uint256 i = 0; i < _length; i++) {
			_sum += _newSeries[i];
			_cumulativeSum[i] = _sum;
			if (_newSeries[i] == 0) {
				_zeros++;
			}
		}
		require(_sum > 1);

		uint256 _maxRuns = 0;
		uint256 _tmp = UINT256_MAX;
		while (_tmp > _sum) {
			_tmp /= _sum;
			_maxRuns++;
		}
		if (_tmp == _sum - 1) {
			_maxRuns++;
		}

		uint256[] memory _resolutions = new uint256[](_length);
		for (uint256 i = 0; i < _length; i++) {
			_resolutions[i] = (_newSeries[i] == 0 ? 0 : FLOAT_SCALAR * _sum / _newSeries[i] / (_length - _zeros));
		}

		Series memory _series = Series({
			sum: _sum,
			maxRuns: _maxRuns,
			series: _newSeries,
			cumulativeSum: _cumulativeSum,
			resolutions: _resolutions
		});
		series.push(_series);
		return series.length - 1;
	}

	function randomRequest(bytes32 _seed) public returns (bytes32 queryId) {
		return _request(RequestType.RANDOM, 0, _seed);
	}

	function modulusRequest(uint256 _modulus, uint256 _betmask, bytes32 _seed) public returns (bytes32 queryId) {
		require(_modulus >= 2 && _modulus <= 256);
		require(_betmask > 0 && _betmask < 2**_modulus - 1);

		ModulusInfo memory _modulusInfo = ModulusInfo({
			modulus: _modulus,
			betmask: _betmask
		});
		modulusInfo.push(_modulusInfo);
		uint256 _requestIndex = modulusInfo.length - 1;
		return _request(RequestType.MODULUS, _requestIndex, _seed);
	}

	function seriesRequest(uint256 _seriesIndex, uint256 _runs, bytes32 _seed) public returns (bytes32 queryId) {
		require(_seriesIndex < series.length);
		require(_runs > 0 && _runs <= series[_seriesIndex].maxRuns);

		SeriesInfo memory _seriesInfo = SeriesInfo({
			seriesIndex: uint128(_seriesIndex),
			runs: uint128(_runs)
		});
		seriesInfo.push(_seriesInfo);
		uint256 _requestIndex = seriesInfo.length - 1;
		return _request(RequestType.SERIES, _requestIndex, _seed);
	}

	function resolveQuery(bytes32 _queryId) public {
		require(block.number - requestMap[_queryId].placedBlockNumber > 256);
		_queryFailed(_queryId);
	}


	function getSeries(uint256 _seriesIndex) public view returns (uint256 sum, uint256 maxRuns, uint256[] memory values, uint256[] memory cumulativeSum, uint256[] memory resolutions) {
		require(_seriesIndex < series.length);
		Series memory _series = series[_seriesIndex];
		return (_series.sum, _series.maxRuns, _series.series, _series.cumulativeSum, _series.resolutions);
	}


	function _request(RequestType _requestType, uint256 _requestIndex, bytes32 _seed) internal returns (bytes32 queryId) {
		LINK.transferFrom(msg.sender, address(this), fee);
		queryId = requestRandomness(keyHash, fee);
		RequestInfo memory _requestInfo = RequestInfo({
			seed: keccak256(abi.encodePacked(_seed, queryId)),
			caller: Caller(msg.sender),
			placedBlockNumber: uint32(block.number),
			requestType: _requestType,
			requestIndex: uint32(_requestIndex)
		});
		requestMap[queryId] = _requestInfo;
	}

	function fulfillRandomness(bytes32 _queryId, uint256 _result) internal override {
		RequestInfo memory _requestInfo = requestMap[_queryId];
		require(address(_requestInfo.caller) != address(0x0));

		if (_requestInfo.placedBlockNumber < block.number && block.number - _requestInfo.placedBlockNumber < 256) {
			if (_requestInfo.requestType == RequestType.RANDOM) { _randomCallback(_queryId, _result); }
			else if (_requestInfo.requestType == RequestType.MODULUS) { _modulusCallback(_queryId, _result); }
			else if (_requestInfo.requestType == RequestType.SERIES) { _seriesCallback(_queryId, _result); }
		} else {
			_queryFailed(_queryId);
		}
	}

	function _randomCallback(bytes32 _queryId, uint256 _result) internal {
		Caller _caller = requestMap[_queryId].caller;
		bytes32 _randomData = _generateRNG(_queryId, _result);
		delete requestMap[_queryId];
		_caller.randomCallback(_queryId, _randomData);
	}

	function _modulusCallback(bytes32 _queryId, uint256 _result) internal {
		RequestInfo memory _requestInfo = requestMap[_queryId];
		uint256 _rng = uint256(_generateRNG(_queryId, _result));

		ModulusInfo memory _modulusInfo = modulusInfo[_requestInfo.requestIndex];
		uint256 _roll = _rng % _modulusInfo.modulus;
		uint256 _resolution = 0;
		if (2**_roll & _modulusInfo.betmask != 0) {
			uint256 _selected = 0;
			uint256 _n = _modulusInfo.betmask;
			while (_n > 0) {
				if (_n % 2 == 1) _selected++;
				_n /= 2;
			}
			_resolution = FLOAT_SCALAR * _modulusInfo.modulus / _selected;
		}

		Caller _caller = _requestInfo.caller;
		delete modulusInfo[_requestInfo.requestIndex];
		delete requestMap[_queryId];
		_caller.modulusCallback(_queryId, _resolution, _roll);
	}

	function _seriesCallback(bytes32 _queryId, uint256 _result) internal {
		RequestInfo memory _requestInfo = requestMap[_queryId];
		uint256 _rng = uint256(_generateRNG(_queryId, _result));

		SeriesInfo memory _seriesInfo = seriesInfo[_requestInfo.requestIndex];
		Series memory _series = series[_seriesInfo.seriesIndex];

		uint256[] memory _results = new uint256[](_seriesInfo.runs);
		uint256 _resolution = 0;
		for (uint256 i = 0; i < _seriesInfo.runs; i++) {
			uint256 _roll = _rng % _series.sum;
			_rng /= _series.sum;

			uint256 _outcome;
			for (uint256 j = 0; j < _series.cumulativeSum.length; j++) {
				if (_roll < _series.cumulativeSum[j]) {
					_outcome = j;
					break;
				}
			}

			_results[i] = _outcome;
			_resolution += _series.resolutions[_outcome];
		}
		_resolution /= _seriesInfo.runs;

		Caller _caller = _requestInfo.caller;
		delete seriesInfo[_requestInfo.requestIndex];
		delete requestMap[_queryId];
		_caller.seriesCallback(_queryId, _resolution, _results);
	}

	function _queryFailed(bytes32 _queryId) internal {
		RequestInfo memory _requestInfo = requestMap[_queryId];
		require(address(_requestInfo.caller) != address(0x0));

		Caller _caller = _requestInfo.caller;
		if (_requestInfo.requestType == RequestType.MODULUS) { delete modulusInfo[_requestInfo.requestIndex]; }
		else if (_requestInfo.requestType == RequestType.SERIES) { delete seriesInfo[_requestInfo.requestIndex]; }
		delete requestMap[_queryId];
		_caller.queryFailed(_queryId);
	}


	function _generateRNG(bytes32 _queryId, uint256 _result) internal view returns (bytes32 _randomData) {
		RequestInfo memory _requestInfo = requestMap[_queryId];
		bytes32 _staticData = keccak256(abi.encodePacked(_requestInfo.seed, _queryId, blockhash(_requestInfo.placedBlockNumber), blockhash(block.number - 1)));
		return keccak256(abi.encodePacked(_staticData, _result));
	}
}