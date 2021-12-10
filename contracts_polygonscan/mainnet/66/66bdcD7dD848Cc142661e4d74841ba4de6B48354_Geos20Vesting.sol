/**
 *Submitted for verification at polygonscan.com on 2021-12-10
*/

/*
 $$$$$$\                         $$\          $$\    $$\ $$$$$$$$\  $$$$$$\  $$$$$$$$\ $$$$$$\ $$\   $$\  $$$$$$\  
$$  __$$\                      $$$$$$\        $$ |   $$ |$$  _____|$$  __$$\ \__$$  __|\_$$  _|$$$\  $$ |$$  __$$\ 
$$ /  \__| $$$$$$\   $$$$$$\  $$  __$$\       $$ |   $$ |$$ |      $$ /  \__|   $$ |     $$ |  $$$$\ $$ |$$ /  \__|
$$ |$$$$\ $$  __$$\ $$  __$$\ $$ /  \__|      \$$\  $$  |$$$$$\    \$$$$$$\     $$ |     $$ |  $$ $$\$$ |$$ |$$$$\ 
$$ |\_$$ |$$$$$$$$ |$$ /  $$ |\$$$$$$\         \$$\$$  / $$  __|    \____$$\    $$ |     $$ |  $$ \$$$$ |$$ |\_$$ |
$$ |  $$ |$$   ____|$$ |  $$ | \___ $$\         \$$$  /  $$ |      $$\   $$ |   $$ |     $$ |  $$ |\$$$ |$$ |  $$ |
\$$$$$$  |\$$$$$$$\ \$$$$$$  |$$\  \$$ |         \$  /   $$$$$$$$\ \$$$$$$  |   $$ |   $$$$$$\ $$ | \$$ |\$$$$$$  |
 \______/  \_______| \______/ \$$$$$$  |          \_/    \________| \______/    \__|   \______|\__|  \__| \______/ 
                               \_$$  _/                                                                            
                                 \ _/                                                                              
                                                                                                                  
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CustomVesting20
 * @dev contract to customize vesting for ERC20 tokens; a schedule
 * based return functions and vesting for any address :WHITELISTED:
 * by the owner, the main vesting schedule will be customized in 
 * a uint256 based arrays for how many days and the release amount
 * based on 1000 percentage points.
 * these schedules are entered by the owner of the contract
 * in which these vestings are publicly avaliable
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

interface GEOS20 {
    function transfer(address _to, uint256 _amount) external returns(bool);
}

contract Geos20Vesting is Ownable {
    struct Schedule {
        uint256[] timestamps;
        uint256[] release;
        bool _vested;
        bool _canVest;
        uint256 maxInvestment;
        uint256 nVested;
        uint256 pricePer;
    }
    mapping(address => Schedule) private _schedules;
    address public _token;
    address[] private allVestors;
    // TGE time in unix as a variable.
    uint256 tgeTimeUnix;

    constructor(address tokenAddr_, uint256 launchTime_) {
        _token = tokenAddr_;
        tgeTimeUnix = launchTime_;
    }
    
    function setLaunchTime(uint256 _change) public onlyOwner {
        tgeTimeUnix = _change;
    }
    
    // check total vesting amount.

    function getVestingSchedule(address vestor) public view returns(Schedule memory){
        return(_schedules[vestor]);
    }
    
    function canVest(address vestorQ) public view returns(bool){
        return(_schedules[vestorQ]._canVest);
    }
    
    function isVestor(address vestorQ) public view returns(bool){
        return(_schedules[vestorQ]._vested);
    }
    
    function getMaxVestingNative(address vestorQ) public view returns(uint256){
        return(_schedules[vestorQ].maxInvestment);
    }
    
    // function addVestor(address nVestor, uint256[] calldata perDays, uint256[] calldata rls, uint256 maxN, uint256 pp) public onlyOwner {
    //     require(!_schedules[nVestor]._vested, "You cannot vest the same address more than once");
    //     require(perDays.length == rls.length, "Release And Timestamps should match");
    //     checkVestingSch(rls);    
    //     _schedules[nVestor] = Schedule(transfromArrDS(perDays), rls, false, true, maxN, 0, pp);
    // }
    
    function transfromArrDS(uint256[] calldata perDays) internal view returns(uint256[] memory){
        uint256[] memory _timestamps = new uint256[](perDays.length);
        for(uint256 i=0; i<perDays.length; i++){
            _timestamps[i] = getDaysInSecondsFrom(perDays[i]);
        }
        return _timestamps;
    }
    
    function checkVestingSch(uint256[] calldata releases) internal pure {
        uint256 tmp;
        for(uint256 i=0; i< releases.length; i++){
            tmp+= releases[i];
        }
        require(tmp == 1000, "Release schedule doesn't add to 1000");
    }
    
    function getDaysInSecondsFrom(uint256 _amountOfDays) public view returns(uint256){
        uint256 _inseconds = _amountOfDays*86400;
        return(tgeTimeUnix + _inseconds);
    }
    
    function checkWithdrawAmount(address vestor) public view returns(uint256,uint256){
        Schedule memory _sch = _schedules[vestor];
        uint256 totalReturn;
        uint256 reqTime = block.timestamp;
        if (_sch.nVested > 0){
                for (uint256 i=0; i<_sch.release.length; i++){
                    if( reqTime>= _sch.timestamps[i]){
                        totalReturn += _sch.release[i];
                }
            }
        }
        return(calculateReturn(totalReturn, _sch.nVested, _sch.pricePer),reqTime);
    }
    
    function calculateReturn(uint256 _total1kPercent, uint256 _totalInvestment, uint256 _price) internal pure returns(uint256){
        return((_totalInvestment*_total1kPercent*_price)/1000);
    }
    
    function getReturnFromVesting() public {
        // sufficent check
        require(isVestor(msg.sender),"Has to be a vestor to get returns");
        Schedule storage _sch = _schedules[msg.sender];
        uint256 _ogLen = _sch.timestamps.length;
        (uint256 _totalToWithdraw, uint256 reqTime) = checkWithdrawAmount(msg.sender);
        require(_totalToWithdraw > 0, "No more to withdraw currently");
        require(GEOS20(_token).transfer(msg.sender, _totalToWithdraw), "Unable to transfer tokens");
        for (uint256 i=0; i<_ogLen; i++){
            if(_sch.timestamps[i] <= reqTime){
                delete _sch.timestamps[i];
                delete _sch.release[i];
            }
        }
    }
    
    // function vestSome() public payable {
    //     require(canVest(msg.sender), "Cannot Vest");
    //     Schedule storage _sch = _schedules[msg.sender];
    //     require(_sch.maxInvestment >= msg.value);
    //     _sch._canVest = false;
    //     _sch.nVested = msg.value;
    //     _sch._vested = true;
    //     allVestors.push(msg.sender);
    // }
    
    function addTeamVesting(address nVestor, uint256[] calldata perDays, uint256[] calldata rls, uint256 teamValNative, uint256 pp) public onlyOwner {
        require(!_schedules[nVestor]._vested, "You cannot vest the same address more than once");
        require(perDays.length == rls.length, "Release And Timestamps should match");
        checkVestingSch(rls); 
        _schedules[nVestor] = Schedule(transfromArrDS(perDays), rls, true, false, teamValNative, teamValNative, pp);
    }
    
    // function withdraw() public onlyOwner {
    //     require(payable(msg.sender).send(address(this).balance));
    // }
    
    // function withdrawGeos(address _to, uint256 amount) public onlyOwner {
    //     require(GEOS20(_token).transfer(_to, amount));
    // }
    
    function getAllVestors() public view onlyOwner returns(address[] memory) {
        return(allVestors);
    }
    
    
    function getTotalVesting(address vestorQ) public view returns(uint256) {
        return(calculateReturn(1000,_schedules[vestorQ].nVested,_schedules[vestorQ].pricePer));
    }
    
    
    
}