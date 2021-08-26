/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFilChainStatOracle {
    function sectorInitialPledge() external view returns(uint256);
    function minerAdjustedPower(string memory _minerId) external view returns(uint256);
    function minerMiningEfficiency(string memory _minerId) external view returns(uint256);
    function minerSectorInitialPledge(string memory _minerId) external view returns(uint256);
    function minerTotalAdjustedPower() external view returns(uint256);
    function avgMiningEfficiency() external view returns(uint256);
    function latest24hBlockReward() external view returns(uint256);
    function rewardAttenuationFactor() external view returns(uint256);
    function networkStoragePower() external view returns(uint256);
    function dailyStoragePowerIncrease() external view returns(uint256);
    function removeMinerAdjustedPower(string memory _minerId) external;
    
}


library StringUtil {
    
    function equal(string memory a, string memory b) internal pure returns(bool){
        return equal(bytes(a),bytes(b));
    }

    function equal(bytes memory a, bytes memory b) internal pure returns(bool){
        return keccak256(a) == keccak256(b);
    }
    
    function notEmpty(string memory a) internal pure returns(bool){
        return bytes(a).length > 0;
    }

}

contract MinerManage is Ownable{
    using StringUtil for string;

    struct MinerInfo{
        string minerId;
        string data;
        string signature;
    }

    IFilChainStatOracle public oracleAddress;
    mapping(address=>MinerInfo) public minerInfoMap;
    mapping(address=>bool) public whiteList;
    mapping(string=>address) public minerIdToWalletMap;
    string[] public minerList;

    event AddMiner(address walletAddress, string minerId);
    event RemoveMiner(address walletAddress, string minerId);
    event FilChainStatOracleChanged(address filChainStatOracle, address _filChainStatOracle);

    constructor(IFilChainStatOracle _oracleAddress){
        oracleAddress = _oracleAddress;
    }

    function setOracleAddress(IFilChainStatOracle _oracleAddress) public onlyOwner{
        require(address(_oracleAddress) != address(0), "address should not be 0");
        emit FilChainStatOracleChanged(address(oracleAddress), address(_oracleAddress));
        oracleAddress = _oracleAddress;
    }

    function addToWhiteList(address walletAddress, string memory minerId, string memory data, string memory signature) public onlyOwner{
        require(walletAddress!=address(0), "wallet address cannot be 0");
        
        address prevAddress = minerIdToWalletMap[minerId];
        if(prevAddress != address(0)){
            whiteList[prevAddress] = false;
            delete minerInfoMap[prevAddress];
        }

        whiteList[walletAddress] = true;

        if(minerIdToWalletMap[minerId] == address(0)){
            minerList.push(minerId);
        }

        minerInfoMap[walletAddress] = MinerInfo(minerId, data, signature);
        minerIdToWalletMap[minerId] = walletAddress;

        emit AddMiner(walletAddress, minerId);
    }

    function removeFromWhiteList(address walletAddress) public onlyOwner{
        string memory minerId = minerInfoMap[walletAddress].minerId;
        
        if(minerId.notEmpty()){
            whiteList[walletAddress] = false;
            delete minerInfoMap[walletAddress];
            delete minerIdToWalletMap[minerId];

            for(uint i=0; i<minerList.length; i++){
                if(minerList[i].equal(minerId)){
                    minerList[i] = minerList[minerList.length-1];
                    minerList.pop();
                    emit RemoveMiner(walletAddress,minerId);
                    break;
                }
            }

            oracleAddress.removeMinerAdjustedPower(minerId);
        }
    }

    function minerAdjustedStoragePowerInTiB(string memory minerId) external view returns(uint256){
        return oracleAddress.minerAdjustedPower(minerId);
    }

    function getMinerId(address walletAddress) public view returns(string memory){
        return minerInfoMap[walletAddress].minerId;
    }

    function getMinerList() external view returns(string[] memory){
        return minerList;
    }

}