// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity >=0.6.0 <0.8.0;

import './safemath.sol';
import './IERC20.sol';
//import "https://raw.githubusercontent.com/smartcontractkit/chainlink/develop/evm-contracts/src/v0.6/ChainlinkClient.sol";

contract employmentContract is /*ChainlinkClient,*/Ownable{
    using SafeMath for uint256;
    
    address payable [] employees;
    mapping (address => bool) hasWorked;
    IERC20 incentive;
    //uint256 blockEnd;
    //uint256 numberOfDeliveries;
    uint256 minimumPaymentPerHour=11; //set to 11 Eur, it could be Eth or bnb
    struct delivery{
        address employee;
        bool isUnfavorableWeather;
        uint256 startBlock;
        uint256 endBlock;
        uint256 latitude;
        uint256 longitude;
        uint256 start; //counted in time there
        uint256 end;
        uint256 fatigue;
        bool accident;
        bool isNight;
        bool isHoliday;
    }
    delivery [] deliveries;
    
    //address private oracle;
    //bytes32 private jobId;
    //uint256 private fee;
    //bytes32 private apiKey;
    mapping (address => bool) registeredIoT;
    mapping (address => uint256) incentiveAmount;
    
    event depositMade(uint256 amount);
    event reviewMade(uint256 numberOfDeliveries, string review);
    event paymentMade(uint256 amount,address employee);
    
    constructor (address [] memory _registeredIoT, IERC20 _incentive) public{
        incentive=_incentive;
        
        //blockEnd=_blockEnd;
        //setPublicChainlinkToken();
        //numberOfDeliveries=_numberOfDeliveries; //no fixed umber of deliveries
        //oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
        //jobId = "29fa9aa13bf1468788b7cc4a500a45b8";
        //fee = 0.1 * 10 ** 18; // 0.1 LINK
        //apiKey= "63cdc582c5324d258f0153931211103";
        for(uint256 i=0;i<_registeredIoT.length;i++){
            registeredIoT[_registeredIoT[i]]=true;
        }
    }
    
    function employeeRegistration() external{
        employees.push(msg.sender);
    }
    
    //params are collected from IoT devices -> smartband with nfc -> smartphone app
    function addDelivery(uint256 latitude, uint256 longitude, uint256 fatigue, bool accident, bool isNight, uint256 start, uint256 end, bool isUnfavorableWeather, bool isHoliday, address worker) external{
        //Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        require(registeredIoT[msg.sender],"IoT device is not registered");
        //only registered IoT devices can sign the transaction. A checksum on the device integrity is reccomended
        // Set the URL to perform the GET request on
        //request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD");
        //return sendChainlinkRequestTo(oracle, request, fee);
        delivery memory del;
        del.employee=worker;
        del.isUnfavorableWeather=isUnfavorableWeather;
        del.isNight=isNight;
        del.end=end;
        del.start=start;
        del.latitude=latitude;
        del.longitude=longitude;
        del.fatigue=fatigue;
        del.accident=accident;
        del.isHoliday=isHoliday;
        deliveries.push(del);
        hasWorked[worker]=true;
    }
    
    //accept from the employer, but the employee could be payed after each delivery
    function acceptJob (address payable employee) external onlyOwner {
        uint256 calculatePay=0;
        for(uint256 i=0;i<deliveries.length;i++){
            if(deliveries[i].employee==employee){
                uint256 workHours=(deliveries[i].end-deliveries[i].start).div(uint256(60).mul(60));
                if(deliveries[i].isNight && deliveries[i].isHoliday && deliveries[i].isUnfavorableWeather)
                    calculatePay=calculatePay+(minimumPaymentPerHour+minimumPaymentPerHour.mul(20).div(100)).mul(workHours);
                /*if(deliveries.accident)
                    do something*/
                else if((deliveries[i].isNight && deliveries[i].isHoliday) || (deliveries[i].isNight && deliveries[i].isUnfavorableWeather) || (deliveries[i].isHoliday && deliveries[i].isUnfavorableWeather))
                    calculatePay=calculatePay+(minimumPaymentPerHour+minimumPaymentPerHour.mul(15).div(100)).mul(workHours);
                else if(deliveries[i].isNight || deliveries[i].isHoliday || deliveries[i].isUnfavorableWeather)
                    calculatePay=calculatePay+(minimumPaymentPerHour+minimumPaymentPerHour.mul(10).div(100)).mul(workHours);
            }
        }
        //fatigue for payment calculation ?
        //nft or event for PA
        incentiveAmount[employee]=incentiveAmount[employee]+calculatePay; //it could be also based on the price, it mesures the work of the employee
        employee.transfer(calculatePay);
        emit paymentMade(calculatePay,employee);
    }
    
    function deposit() external payable onlyOwner {
        emit depositMade(msg.value);
    }
    
    
    function addIoT(address IoT) external onlyOwner{
        registeredIoT[IoT]=true;
    }
    
    function removeIoT(address IoT) external onlyOwner{
         registeredIoT[IoT]=false;
    }
    
    function makeReview(string memory reviewReference) external { 
        require(hasWorked[msg.sender],"you are not an employee");
        incentive.mint(msg.sender, incentiveAmount[msg.sender]); // mint and send an incentive ERC20 to the reviewer, chainlink to retrieve the price
        emit reviewMade(deliveries.length,reviewReference);
    }
    
}