pragma solidity 0.4.24;

interface IndexInterface {
    function getBBFarm(uint8) external view returns (BBFarmInterface);
    function getBBFarmID(bytes4) external view returns (uint8);
    function getBackend() external view returns (BackendInterface);
}

interface BackendInterface {
    function getDBallotID(bytes32, uint) external view returns (uint256);
}

interface BBFarmInterface {
    function getDetails(uint, address) external view returns 
        ( bool hasVoted
        , uint nVotesCast
        , bytes32 secKey
        , uint16 submissionBits
        , uint64 startTime
        , uint64 endTime
        , bytes32 specHash
        , bool deprecated
        , address ballotOwner
        , bytes16 extraData 
        );
}


contract BBFarmAux2 {
    function _ballotIdToNamespace(uint ballotId) internal pure returns (bytes4) {
        return bytes4(ballotId >> 224);
    }
    
    function getBBFarmAddressFromBallotId(IndexInterface ix, uint256 ballotId) internal view returns (address) {
        return ix.getBBFarm(ix.getBBFarmID(_ballotIdToNamespace(ballotId)));
    }
    
    function getBallotId(BackendInterface ixBackend, bytes32 democHash, uint ballotN) internal view returns (uint ballotId) {
        ballotId = ixBackend.getDBallotID(democHash, ballotN);
    }
    
    function getBBFarmAddressAndBallotId(IndexInterface ix, bytes32 democHash, uint ballotN) external view returns (address bbFarmAddress, uint256 ballotId) {
        ballotId =  getBallotId(ix.getBackend(), democHash, ballotN);
        bbFarmAddress = getBBFarmAddressFromBallotId(ix, ballotId);
    }
    
    function getBallotDetails(uint ballotId, BBFarmInterface bbFarm, address voterAddress) external view returns 
        ( bool hasVoted
        , uint nVotesCast
        , bytes32 secKey
        , uint16 submissionBits
        , uint64 startTime
        , uint64 endTime
        , bytes32 specHash
        , bool deprecated
        , address ballotOwner
        , bytes16 extraData 
        )
    {
        return bbFarm.getDetails(ballotId, voterAddress);
    }
    
    function ballotIdToDetails(IndexInterface ix, uint ballotId) external view returns 
        ( uint nVotesCast
        , bytes32 secKey
        , uint16 submissionBits
        , uint64 startTime
        , uint64 endTime
        , bytes32 specHash
        , bool deprecated
        // , address ballotOwner
        // , bytes16 extraData 
        )
    {
        BBFarmInterface bbFarm = ix.getBBFarm(ix.getBBFarmID(_ballotIdToNamespace(ballotId)));
        (, nVotesCast, secKey, submissionBits, startTime, endTime, specHash, deprecated,,) = bbFarm.getDetails(ballotId, address(0));
    }
    
}