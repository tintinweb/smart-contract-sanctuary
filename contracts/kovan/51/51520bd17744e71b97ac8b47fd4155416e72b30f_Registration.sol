/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface ILendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);
}

contract Creator {
    ILendingPool lendingPool;
    IERC20 wethToken;
    address creatorAddr;
    
    uint public totalFanCount;
    uint public totalRawDepositCount;
    uint public totalDepositValue;

    mapping (address => uint) public fanAmount;
    
    // Mainnet WETH 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
    // Kovan WETH 0xd0A1E359811322d97991E03f863a0C30C2cF029C
    // Rinkeby WETH 0xc778417e063141139fce010982780140aa0cd5ab
    constructor(address assetAddr, address aLendingPoolAddr, address creatorAddrParam) {
        creatorAddr = creatorAddrParam;
        lendingPool = ILendingPool(aLendingPoolAddr);
        wethToken = IERC20(assetAddr);
    }
    
    modifier onlyCreator() {
        require(msg.sender == creatorAddr, "Not Creator");
        _;
    }
    
    modifier onlyFan() {
        require(fanAmount[msg.sender] > 0, "Not a fan!");
        _;
    }

    function _depositIntoAavePool (
        uint256 amount
    ) internal {
        if (amount > 0) {
            wethToken.approve(address(lendingPool), amount);
            lendingPool.deposit(address(wethToken), amount, address(this), 0);
        }

        // aTokensRec = IERC20(aToken).balanceOf(msg.sender) - initialBalance;
        // require(aTokensRec > minATokens, "High Slippage");
    }
    
    function currentContractBalance() public view returns (uint) {
        return wethToken.balanceOf(address(this));
    }
    
    function deposit(uint amount) public {
        require(amount > 0, "Invalid amount");
        
        bool success = wethToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer to contract failed");
        
        if (fanAmount[msg.sender] == 0) {
            totalFanCount += 1;
        }
        
        fanAmount[msg.sender] += amount;
        totalDepositValue += amount;
        totalRawDepositCount += 1;
        _depositIntoAavePool(amount);
    }
    
    function withdrawForCreator() public onlyCreator {
        uint withdrawnAmount = lendingPool.withdraw(address(wethToken), type(uint).max, address(this));
        uint interest = withdrawnAmount - totalDepositValue;
        
        wethToken.approve(msg.sender, interest);
        wethToken.transfer(msg.sender, interest);
        
        _depositIntoAavePool(currentContractBalance());
    }
    
    function withdrawForFan() public onlyFan {
        lendingPool.withdraw(address(wethToken), fanAmount[msg.sender], address(this));
        
        wethToken.approve(msg.sender, fanAmount[msg.sender]);
        wethToken.transfer(msg.sender, fanAmount[msg.sender]);
        
        _depositIntoAavePool(currentContractBalance());
        fanAmount[msg.sender] = 0;
        totalFanCount -= 1;
        totalDepositValue -= fanAmount[msg.sender];
    }
}


contract Registration {
    uint public maxCreatorCount;
    
    struct CreatorData {
        string metadata;
    }
    
    event CreatorAdded(string metadata);
    
    mapping (address => uint) public creatorAddrToId;
    mapping (uint => address) public creatorToContract;
    
    CreatorData[] allCreators;
    address assetAddr;
    address aLendingPoolAddr;
    
    constructor (address _assetAddr, address _aLendingPoolAddr) {
        assetAddr = _assetAddr;
        aLendingPoolAddr = _aLendingPoolAddr;
        
        allCreators.push(CreatorData("Paradise Biryani"));
    }
    
    function addCreator(string memory metadata) public {
        require(creatorAddrToId[msg.sender] == 0, "Creator already exists");

        CreatorData memory creator = CreatorData(metadata);
        allCreators.push(creator);
        maxCreatorCount++;
        
        creatorAddrToId[msg.sender] = maxCreatorCount;
        
        Creator creatorContract = new Creator(assetAddr, aLendingPoolAddr, msg.sender);
        creatorToContract[maxCreatorCount] = address(creatorContract);
        
        emit CreatorAdded(metadata);
    }
    
    function getCreator(uint creatorIdx) public view returns (string memory) {
        require(creatorIdx <= maxCreatorCount, "Creator does not exist");
        return allCreators[creatorIdx].metadata;
    }
    
    function getCreators(uint startCreatorIdx, uint numOfCreators) public view returns (string[] memory) {
        string[] memory creatorsToReturn = new string[](numOfCreators);
        
        for (uint i=0; i < numOfCreators; i++) {
            if ((startCreatorIdx + i) < allCreators.length) {
                creatorsToReturn[i] = allCreators[startCreatorIdx + i].metadata;
            }
        }
        
        return creatorsToReturn;
    }
    
    function editCreator(string memory metadata) public {
        uint creatorIdx = creatorAddrToId[msg.sender];
        
        require(creatorIdx > 0, "Invalid Creator Address");
        
        CreatorData storage creatorData = allCreators[creatorIdx];
        creatorData.metadata = metadata;
    }
    
}