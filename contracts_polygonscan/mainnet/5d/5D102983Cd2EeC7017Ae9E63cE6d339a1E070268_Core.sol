pragma solidity ^0.6.6;

import "./ICore.sol";
import "./Iincentive.sol";
import "./IPcv.sol";
import "./Context.sol";
import "./Address.sol";

contract Core is ICore{

    address public _dpcp;

    address public _admin;

    Iincentive public incentiveContract;
    IPcv public pcvContract;

    bool public _openIncentive = false;
    bool public _openPcv = false;

    mapping(address => bool) excludeIncentive;
    mapping(address => bool) excludePcv;

    mapping(address => bool) minters;
    mapping(address => bool) burners;

    constructor() public{
        _admin = msg.sender;
    }

    function setDpcp(address token) external onlyAdmin {
        _dpcp = token;
    }

    function setIncentiveContract(address _incentiveContract) external onlyAdmin {
        incentiveContract = Iincentive(_incentiveContract);
    }

    function setPcvContract(address _pcvContract) external onlyAdmin {
        pcvContract = IPcv(_pcvContract);
    }

    function setIncentiveEnable(bool _isEnable) external onlyAdmin {
        require(address(incentiveContract) != address(0),"Core: incentive contract address is 0");
        _openIncentive = _isEnable;
    }

    function setPcvEnable(bool _isEnable) external onlyAdmin {
        require(address(pcvContract) != address(0),"Core: pcv contract address is 0");
        _openPcv = _isEnable;
    }

    function getIncentiveState() external view override returns(bool){
        return _openIncentive;
    }

    function getPcvState() external view override returns(bool){
        return _openPcv;
    }

    function setMinter(address account) external onlyAdmin{
        minters[account] = true;
    }

    function setBurner(address account) external onlyAdmin{
        burners[account] = true;
    }

    function removeMinter(address account) external onlyAdmin{
        delete minters[account] ;
    }

    function removeBurner(address account) external onlyAdmin{
        delete burners[account] ;
    }

    function isMinter(address account) external override view returns(bool){
        if(minters[account] == true){
            return true;
        }
        return false;
    }

    function isBurner(address account)  external override view returns(bool){
        if(burners[account] == true){
            return true;
        }
        return false;
    }

    function executeExtra(address sender,address recipient,uint256 amount) external override onlyDpcp returns(uint256) {
        uint256  newAmount = executePcv(sender,recipient,amount);
        newAmount = executeIncentive(sender,recipient,newAmount);
        return newAmount;
    }

    function executePcv(address sender,address recipient,uint256 amount) internal returns(uint256){
        if(excludePcv[sender] || excludePcv[recipient]){
            return amount;
        }
        if(!_openPcv){
            return amount;
        }

        uint256 newAmount = pcvContract.execute(sender,recipient,amount);
        emit executedPcv(sender,recipient,amount);
        return newAmount;
    }

    function executeIncentive(address sender,address recipient,uint256 amount) internal returns(uint256){
        if(excludeIncentive[sender] || excludeIncentive[recipient]){
            return amount;
        }
        if(!_openIncentive){
            return amount;
        }

        uint256 newAmount = incentiveContract.execute(sender,recipient,amount);
        emit executedIncentive(sender,recipient,amount);
        return newAmount;
    }

    modifier onlyDpcp(){
        require( _dpcp == msg.sender,"Core: caller is not dpcp");
        _;
    }

    function ifGetReward() external view override returns(bool){
        return incentiveContract.priceOverAvg();
    }

    function getTotalReward() external view override returns(uint256){
        uint256 _totalReward;
        if(address(incentiveContract) != address(0)){
            _totalReward = incentiveContract.getTotalReward();
        }
        if(address(pcvContract) != address(0)){
            _totalReward += pcvContract.getTotalFee();
        }
        return _totalReward;
    }

    function isExcludeIncentive(address account) public view returns(bool){
        return excludeIncentive[account];
    }

    function isExcludePcv(address account) public view returns(bool){
        return excludePcv[account];
    }

    function setExcludeIncentive(address account) external onlyAdmin{
        excludeIncentive[account] = true;
    }

    function removeExcludePcv(address account) external onlyAdmin{
        delete excludePcv[account];
    }

    function removeExcludeIncentive(address account) external onlyAdmin{
        delete excludeIncentive[account];
    }

    function setExcludePcv(address account) external onlyAdmin{
        excludePcv[account] = true;
    }

    event executedPcv(address sender,address recipient,uint256 amount);
    event executedIncentive(address sender,address recipient,uint256 amount);

    modifier onlyAdmin() {
        require(_admin == msg.sender,"Core: caller is not admin");
        _;
    }

}