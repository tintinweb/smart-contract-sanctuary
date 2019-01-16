pragma solidity 0.4.24;


contract IrisScoreProviderI {

    /// report the IRIS score for the dasaHash records
    /// @param dataHash the hash of the data to be scored
    function report(bytes32 dataHash)
    public
    view
    returns (uint256);
}


contract IrisScoreJSONProvider is IrisScoreProviderI{

    /* Fallback function */
    function () public { }

    // dataHash => score mapping
    mapping(bytes32 => uint256) public scores;

    function report(bytes32 dataHash) public view returns (uint256) {
        require(dataHash != 0);
        uint256 result = scores[dataHash];
        require(result > 0);
        return result;
    }

    function setVal(bytes32 dataHash, uint256 newValue) public {
        require(dataHash != 0);
        require(newValue > 0);
        scores[dataHash] = newValue;
    }
}