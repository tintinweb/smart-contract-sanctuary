// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

// Proxy contract use to param all others contract addresses

contract BandzaiAddresses is Ownable { 
    address oracleAddress;
    address BZAITokenAddress;
    address monsterNFTAddress;
    address laboratoryAddress;
    address nurseryAddress;
    address potionAddress;
    address trainingAddress;
    address stakingAddress;
    address teamAddress;
    address gameAddress;
    address eggsAddress;
    address lotteryAddress;
    address paymentsAddress;
    address challengeRewardsAddress;
    address winRewardsAddress;
    address openAndCloseAddress;
    address alchemyAddress;
    address farmAnimalsAddress;
    address reserveChallengeAddress;
    address reserveWinAddress;
    address levelStorageAddress;
    address rankingContractAddress;
    address delegateMonsterAddress;

    // use to prevent anybody to mint another datas 
    address authorizedSigner = 0xee14d1F40b1F7111D8412BBeAac05E0aa63e2C80;

    function setBZAI(address _bzai) external onlyOwner {
        BZAITokenAddress = _bzai;
    }

    function setOracle(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
    }

    function setStaking(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }

    function setMonsterNFT(address _monsterNFTAdress) external onlyOwner {
        monsterNFTAddress = _monsterNFTAdress;
    }

    function setLaboratory(address _laboratoryAddress) external onlyOwner {
        laboratoryAddress = _laboratoryAddress;
    }

    function setTrainingCenter(address _trainingAddress) external onlyOwner {
        trainingAddress = _trainingAddress;
    }

    function setNursery(address _nurseryAddress) external onlyOwner {
        nurseryAddress = _nurseryAddress;
    }

    function setPotion(address _potionAddress) external onlyOwner {
        potionAddress = _potionAddress;
    }

    function setTeamAddress(address _teamAddress) external onlyOwner {
        teamAddress = _teamAddress;
    }

    function setGameAddress(address _gameAddress) external onlyOwner {
        gameAddress = _gameAddress;
    }

    function setEggsAddress(address _eggsAddress) external onlyOwner {
        eggsAddress = _eggsAddress;
    }

    function setLotteryAddress(address _lotteryAddress) external onlyOwner {
        lotteryAddress = _lotteryAddress;
    }

    function setPaymentsAddress(address _paymentsAddress) external onlyOwner {
        paymentsAddress = _paymentsAddress;
    }

    function setChallengeRewardsAddress(address _address) external onlyOwner {
        challengeRewardsAddress = _address;
    }

    function setWinRewardsAddress(address _address) external onlyOwner {
        winRewardsAddress = _address;
    }

    function setReserveWinAddress(address _address) external onlyOwner {
        reserveWinAddress = _address;
    }
    
    function setReserveChallenge(address _address) external onlyOwner {
        reserveChallengeAddress = _address;
    }

    function setOpenAndCloseAddress(address _address) external onlyOwner{
        openAndCloseAddress =_address;
    }

    function setAlchemyAddress(address _address) external onlyOwner{
        alchemyAddress =_address;
    }

    function setFarmAnimalsAddress(address _address) external onlyOwner{
        farmAnimalsAddress =_address;
    }

    function setLevelStorageAddress(address _address) external onlyOwner{
        levelStorageAddress =_address;
    }


    function setRankingAddress(address _address) external onlyOwner{
        rankingContractAddress = _address;
    }

    function setSigner(address _address) external onlyOwner {
        authorizedSigner = _address;
    }

    function setDelegateMonsterAddress(address _address) external onlyOwner {
        delegateMonsterAddress = _address;
    }

    function getBZAIAddress() external view returns(address){
        return BZAITokenAddress;
    }

    function getOracleAddress() external view returns(address) {
        return oracleAddress;
    }

    function getStakingAddress() external view returns(address) {
        return stakingAddress;
    }

    function getMonsterAddress() external view returns(address) {
        return monsterNFTAddress;
    }

    function getLaboratoryAddress() external view returns(address) {
        return laboratoryAddress;
    }

    function getTrainingCenterAddress() external view returns(address) {
        return trainingAddress;
    }

    function getNurseryAddress() external view returns(address) {
        return nurseryAddress;
    }

    function getPotionAddress() external view returns(address) {
        return potionAddress;
    }

    function getTeamAddress() external view returns(address){
        return teamAddress;
    }

    function getGameAddress() external view returns(address) {
        return gameAddress;
    }

    function getEggsAddress() external view returns(address) {
        return eggsAddress;
    }

    function getLotteryAddress() external view returns(address) {
        return lotteryAddress;
    }

    function getPaymentsAddress() external view returns(address) {
        return paymentsAddress;
    }

    function getChallengeRewardsAddress() external view returns(address) {
        return challengeRewardsAddress;
    }

    function getWinRewardsAddress() external view returns(address) {
        return winRewardsAddress;
    }

    function getReserveChallengeAddress() external view returns(address) {
        return reserveChallengeAddress;
    }

    function getReserveWinAddress() external view returns(address) {
        return reserveWinAddress;
    }

    function getOpenAndCloseAddress() external view returns(address) {
        return openAndCloseAddress;
    }

    function getAlchemyAddress() external view returns(address) {
        return alchemyAddress;
    }

    function getFarmAnimalsAddress() external view returns(address) {
        return farmAnimalsAddress;
    }

    function getLevelStorageAddress() external view returns(address) {
        return levelStorageAddress;
    }

    function getRankingContract() external view returns(address) {
        return rankingContractAddress;
    }

    function getAuthorizedSigner() external view returns(address){
        return authorizedSigner;
    }

    function getDelegateMonsterAddress() external view returns(address){
        return delegateMonsterAddress;
    }

    function isAuthToManagedNFTs(address _address) external view returns(bool){
        return(
            _address == nurseryAddress ||
            _address == trainingAddress ||
            _address == laboratoryAddress ||
            _address == eggsAddress ||
            _address == gameAddress ||
            _address == lotteryAddress ||
            _address == alchemyAddress
        );
    }

    function isAuthToManagedPayments(address _address) external view returns(bool){
        return(
            _address == laboratoryAddress ||
            _address == lotteryAddress ||
            _address == nurseryAddress ||
            _address == trainingAddress ||
            _address == gameAddress 
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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