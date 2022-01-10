/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

/*
 __      __                                __                             
/\ \  __/\ \  __                          /\ \  __                        
\ \ \/\ \ \ \/\_\  ____      __     _ __  \_\ \/\_\  __  __    ___ ___    
 \ \ \ \ \ \ \/\ \/\_ ,`\  /'__`\  /\`'__\/'_` \/\ \/\ \/\ \ /' __` __`\  
  \ \ \_/ \_\ \ \ \/_/  /_/\ \L\.\_\ \ \//\ \L\ \ \ \ \ \_\ \/\ \/\ \/\ \ 
   \ `\___x___/\ \_\/\____\ \__/.\_\\ \_\\ \___,_\ \_\ \____/\ \_\ \_\ \_\
    '\/__//__/  \/_/\/____/\/__/\/_/ \/_/ \/__,_ /\/_/\/___/  \/_/\/_/\/_/
                                                                          
                                                                          
      __  __                  __                                          
     /\ \/\ \                /\ \__  __                                   
     \ \ \ \ \     __    ____\ \ ,_\/\_\    ___      __                   
      \ \ \ \ \  /'__`\ /',__\\ \ \/\/\ \ /' _ `\  /'_ `\                 
       \ \ \_/ \/\  __//\__, `\\ \ \_\ \ \/\ \/\ \/\ \L\ \                
        \ `\___/\ \____\/\____/ \ \__\\ \_\ \_\ \_\ \____ \               
         `\/__/  \/____/\/___/   \/__/ \/_/\/_/\/_/\/___L\ \              
                                                     /\____/              
                                                     \_/__/               

*/

//SPDX-License-Identifier: GPLv3

pragma solidity >=0.7.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract WizardiumContracts is Ownable {
    mapping(address => bool) private wizContracts;

    function addToWizContracts(address _nContract) public onlyOwner {
        wizContracts[_nContract] = true;
    }

    function removeWizContracts(address _contract) public onlyOwner {
        wizContracts[_contract] = false;
    }

    modifier isWizContract() {
        require(wizContracts[_msgSender()], "Only Wizaridium contracts are able to call");
        _;
    }
}
interface WizzERC20 {
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);    
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract WizardiumVesting is WizardiumContracts {
    event VestingAdded(address vestor, uint256 amount, uint256 totalAmount);
    event VestmentWithdrawn(address vestor, uint256 amount, uint256 totalAmount);

    // Mapping for the total vesting amount by wallet 
    mapping(address => uint256) vestors;
    // Mapping for the last vestment round timestamps
    mapping(address => uint256) times;
    // Mapping for the total withdrawn amount by wallet
    mapping(address => uint256) withdrawals;

    address WIZZY = 0x9E327B55D5791bd1b08222F7886d7a82EB11aCEE;
    uint256 totalVestments;
    uint256 priceBasis = 1 ether;
    uint256 timeForRelease = 864000;
    /**
     * 100/1000 = 0.1 => 10%
     */
    uint256 percentageRelease = 100; 
    uint256 baseForRelease = 1000;

    enum VestingProps {
        TOTALV,
        RELEASETIME,
        RELEASEPERCENT,
        RELEASEBASE
    }

    function changeVestingStructure(VestingProps vp, uint256 val) external onlyOwner {
        if(vp == VestingProps.TOTALV){
            totalVestments = val;
        }else if(vp == VestingProps.RELEASETIME){
            require(val != 0, "Cannot set 0 for time of release");
            timeForRelease = val;
        }else if (vp == VestingProps.RELEASEPERCENT){
            percentageRelease = val;
        }else if (vp == VestingProps.RELEASEBASE){
            baseForRelease = val;
        }else{
            revert("WizardiumVesting: No such vesting property");
        }
    }

    function addPolicyVestment(address farmer, uint256 amount, uint256 ts) public onlyOwner {
        vestors[farmer] += amount;
        totalVestments+= amount;
        times[farmer] = ts;
        emit VestingAdded(farmer, amount, (vestors[farmer]-withdrawals[farmer]));
    }

    function addVestment(address farmer, uint256 amount) public isWizContract {
        vestors[farmer] += amount;
        totalVestments+= amount;
        emit VestingAdded(farmer, amount, (vestors[farmer]-withdrawals[farmer]));
    }

    function sendPayment(address farmer, uint256 total) internal returns(bool) {
        total = total*priceBasis;
        require(WizzERC20(WIZZY).balanceOf(address(this)) > total, "WizardiumVesting: Not enough funds");
        require(WizzERC20(WIZZY).transfer(farmer, total), "WizardiumVesting: Unable to transfer");
        emit VestmentWithdrawn(farmer, total, (vestors[farmer]-withdrawals[farmer]));
        return true;
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        require(WizzERC20(WIZZY).balanceOf(address(this)) > totalVestments+amount, "WizardiumVesting: Unable to withdraw more than combined vestments");
        sendPayment(msg.sender, amount);
    }

    function ownerCheck() external onlyOwner view returns(uint256) {
        return(totalVestments);
    }

    function resetChecks() external onlyOwner {
        totalVestments = 0;
    }

    function farmerWithdraw(address farmer) external isWizContract {
        (, uint256 amnt, uint256 nct) = checkFarmingReturns(farmer);
        require(((amnt > 0) && (nct == 0)), "WizardiumVesting: Nothing avaliable to withdraw");
        _safeWithdraw(farmer, amnt);

    }

    function _checkCTime(uint256 tA, uint256 tB, uint256 dT) internal pure returns(bool){
        return(tB  >= (tA + dT));
    }

    function _calcWithdrawable(uint256 totalV, uint256 totalW, uint256 cTime, uint256 nTime, uint256 dT) internal pure returns(uint256){
        uint256 multp = (nTime - cTime)/dT;
        uint256 total = totalV - totalW;
        return((total*multp));
    }

    function checkFarmingReturns(address farmer) public view returns(uint256 total, uint256 totalWithdrawable, uint256 nextClaimTime){
        totalWithdrawable = 0;
        total = 0;
        uint256 _totalIn = vestors[farmer];
        uint256 _totalOut = withdrawals[farmer];
        uint256 _cTime = times[farmer];
        if(_totalIn > _totalOut){
            total = _totalIn - _totalOut;
        }
        nextClaimTime = _cTime + timeForRelease;
        if(_checkCTime(_cTime, block.timestamp, timeForRelease)){
            nextClaimTime = 0;
            uint256 _tw = _calcWithdrawable(_totalIn,_totalOut, _cTime, block.timestamp, timeForRelease);
            totalWithdrawable = ((_tw*percentageRelease)/baseForRelease);
            if((_totalIn >= _totalOut) && (totalWithdrawable == 0)){
                totalWithdrawable = total;
            }else{
                if(totalWithdrawable > total){
                    totalWithdrawable = total;
                }
            }
        }
    }

    function _safeWithdraw(address _farmer, uint256 _total) internal {
    //    require(sendPayment(_farmer, _total), "WizardiumVesting: Unable to send payment");
       withdrawals[_farmer] += _total;
       times[_farmer] = block.timestamp;
        if(totalVestments > _total){
            totalVestments -= _total;
        }
    }
}