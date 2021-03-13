/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// File: contracts\modules\Ownable.sol

pragma solidity =0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\modules\SafeInt256.sol

pragma solidity =0.5.16;
library SafeInt256 {
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require(((z = x + y) >= x) == (y >= 0), 'SafeInt256: addition overflow');
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require(((z = x - y) <= x) == (y >= 0), 'SafeInt256: substraction underflow');
    }

    function mul(int256 x, int256 y) internal pure returns (int256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeInt256: multiplication overflow');
    }
}

// File: contracts\upkeeper\FNXUpKeeper.sol

pragma solidity =0.5.16;


interface IOptionsKeeper {
    function getOptionCalRangeAll(address[] calldata whiteList)external view returns(uint256,int256,int256,uint256,int256[] memory,uint256,uint256);
    function calculatePhaseOccupiedCollateral(uint256 lastOption,uint256 beginOption,uint256 endOption) external view returns(uint256,uint256,uint256,bool);
    function calculatePhaseOptionsFall(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList) external view returns(int256[] memory);
    function calRangeSharedPayment(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList)external view returns(int256[] memory,uint256[] memory,uint256);
    function setCollateralPhase(uint256 totalCallOccupied,uint256 totalPutOccupied,uint256 beginOption,
        int256 latestCallOccpied,int256 latestPutOccpied) external;
}
interface ICollateralKeeper {
    function setSharedPayment(address[] calldata _whiteList,int256[] calldata newNetworth,int256[] calldata sharedBalances,uint256 firstOption)external;
}
interface IManagerKeeper {
    function getWhiteList()external view returns (address[] memory);
}
contract FNXUpKeeper is Ownable {
    using SafeInt256 for int256;
    uint256 public lastUpdateTime;
    uint256 public updateInterval;
    IOptionsKeeper public optionsKeeper;
    ICollateralKeeper public collateralKeeper;
    IManagerKeeper public managerKeeper;
    constructor (address _optionsKeeper,address _collateralKeeper,address _managerKeeper,uint256 _updateInterval) public{
        optionsKeeper = IOptionsKeeper(_optionsKeeper);
        collateralKeeper = ICollateralKeeper(_collateralKeeper);
        managerKeeper = IManagerKeeper(_managerKeeper);
        updateInterval = _updateInterval;
    }
    function setOptionsKeeper(address _optionsKeeper) public onlyOwner{
        optionsKeeper = IOptionsKeeper(_optionsKeeper);
    }
    function setCollateralKeeper(address _collateralKeeper) public onlyOwner{
        collateralKeeper = ICollateralKeeper(_collateralKeeper);
    }
    function setManagerKeeper(address _managerKeeper) public onlyOwner{
        managerKeeper = IManagerKeeper(_managerKeeper);
    }
    function setUpdateInterval(uint256 _updateInterval) public onlyOwner{
        updateInterval = _updateInterval;
    }
    function checkUpkeep(bytes calldata data) external view returns (bool, bytes memory) {
        //decide if an upkeep is needed and return bool accordingly
        if (now < lastUpdateTime+updateInterval){
            return (false,"");
        }
        address[] memory whiteList = managerKeeper.getWhiteList();
        (uint256 firstOption, int256 latestCallOccupied, int256 latestPutOccupied,
		uint256 netFirstOption, int256[] memory latestNetWorth, uint256 lastOption,) = 
        optionsKeeper.getOptionCalRangeAll(whiteList);
        uint256 totalCallOccupied;
        uint256 totalPutOccupied;
        if(lastOption<=firstOption && lastOption <= netFirstOption){
            return (false,"");
        }
        if (lastOption>firstOption){
            (totalCallOccupied,totalPutOccupied,firstOption,) = optionsKeeper.calculatePhaseOccupiedCollateral(lastOption, firstOption,lastOption);
        }
        int256[] memory newNetworth;
        int256[] memory fallBalance;
        (newNetworth,fallBalance,netFirstOption) =checkUpkeep_Net(netFirstOption,latestNetWorth,lastOption);
        return (true,abi.encode(totalCallOccupied,totalPutOccupied,latestCallOccupied,latestPutOccupied,
            firstOption,newNetworth,fallBalance,netFirstOption));
        
    }
    function checkUpkeep_Net(uint256 netFirstOption, int256[] memory latestNetWorth, uint256 lastOption) internal view
        returns(int256[] memory,int256[] memory,uint256){
        address[] memory whiteList = managerKeeper.getWhiteList();
        int256[] memory newNetworth;
        uint256[] memory sharedBalance;
        int256[] memory fallBalance;
        if (lastOption > netFirstOption){
            (newNetworth,sharedBalance,netFirstOption) =
                        optionsKeeper.calRangeSharedPayment(lastOption,netFirstOption,lastOption,whiteList);
            fallBalance = optionsKeeper.calculatePhaseOptionsFall(lastOption,netFirstOption,lastOption,whiteList);
            for (uint256 i= 0;i<fallBalance.length;i++){
                fallBalance[i] = int256(sharedBalance[i]).sub(latestNetWorth[i]).add(fallBalance[i]);
            }
        }
        return (newNetworth,fallBalance,netFirstOption);
    }

    function performUpkeep(bytes calldata data) external {
        lastUpdateTime = now;
        address[] memory whiteList = managerKeeper.getWhiteList();
        (uint256 totalCallOccupied,uint256 totalPutOccupied,int256 latestCallOccpied,int256 latestPutOccpied,uint256 beginOption,
            int256[] memory newNetworth,int256[] memory fallBalance,uint256 shareFirst)
            = abi.decode(data,(uint256, uint256,int256,int256,uint256,int256[],int256[],uint256));
        if(totalCallOccupied>0 || totalPutOccupied>0 || beginOption> 0){
            optionsKeeper.setCollateralPhase(totalCallOccupied,totalPutOccupied,beginOption,
                latestCallOccpied,latestPutOccpied);
        }
        collateralKeeper.setSharedPayment(whiteList,newNetworth,fallBalance,shareFirst);
    }
}