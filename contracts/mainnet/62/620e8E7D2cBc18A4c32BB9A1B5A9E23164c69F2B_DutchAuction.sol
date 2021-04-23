// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract DutchAuction{

    IERC20 public token;
    mapping (address => uint) public reserve;
    mapping (address => uint) public committed;
    mapping (address => bool) public whitelisted;
    uint256 public startPrice;
    uint256 public tokensLeft;
    uint256 public minPrice;
    address payable public owner;
    uint256 public bought;
    uint256 public price;
    uint256 public tokensStart;
    uint256 public finish;
    uint256 public start;
    bool public whitelistOnly;
    bool public hasClaimed;
    uint256 public open; // 0 = closed, 1 = open, 2 = ended;
    address factory;

    constructor() {
        // Don't allow implementation to be initialized.
        token = IERC20(address(1));
    }

    function initialize(IERC20 _token, address payable _owner, address factory_) external {
        require(address(token) == address(0), "already initialized");
        require(address(_token) != address(0), "token can not be null");

        owner = _owner;
        token = _token;
        factory = factory_;
    }

    function changeOwner(address payable newOwner) external {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }

    function startAuction(
        uint256 min,
        uint256 _startPrice,
        uint256 _start,
        uint256 _finish,
        address[] memory whitelistd,
        bool whitelist
    )
    public
    {
        require(msg.sender == owner, "Not owner");
        require(open == 0, "Auction has started");
        require(_start < _finish, "Start time below finish time");
        require(_finish > block.timestamp, "Finish time must be in the future");
        require(_start >= block.timestamp, "Start time must be in the future");

        finish = _finish;
        start = _start;
        startPrice = _startPrice;
        minPrice = min;
        tokensLeft = token.balanceOf(address(this));
        tokensStart = token.balanceOf(address(this));
        open = 1;
        whitelistOnly = whitelist;

        if (whitelist) {
            for (uint i=0; i < whitelistd.length; i++) {
                whitelisted[whitelistd[i]] = true;
            }
        }

        updateCurrentPrice();
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 returnPrice = startPrice;

        if (open == 1 && block.timestamp >= start) {
            returnPrice = startPrice*(finish - block.timestamp) / (finish - start);
            if (returnPrice < minPrice){
                returnPrice = minPrice;
            }
        }
        if (open == 2) {
            returnPrice = price;
        }

        return returnPrice;
    }

    function updateCurrentPrice() public returns (uint256) {
        require (open != 0, "Auction has not started");

        if (open == 1) {
            if (finish <= block.timestamp){
                open = 2;
            }
            if (block.timestamp >= start) {
                price = startPrice*(finish - block.timestamp) / (finish - start);
                if (price < minPrice){
                    price = minPrice;
                }
            }
        }

        return price;
    }

    function closeAuction() public {
        require (open == 1, "Not active");
        require ((msg.sender == owner && bought == 0) || (block.timestamp > finish),
            "Either not owner and no current bid or auction finish time not reached");

        open = 2;
    }

    function updateWhitelist(address[] memory whitelistd) public{
        require (msg.sender == owner, "Not owner");

        for (uint256 i=0; i < whitelistd.length; i++) {
            whitelisted[whitelistd[i]] = true;
        }
    }

    function bid(uint256 amount) public payable {
        require (open == 1 && block.timestamp >= start, "Not active auction or start time not reached");
        require (msg.value >= updateCurrentPrice() * amount / 10 ** 18, "Not enough payment");
        require (msg.value > 0, "Cant bid with 0");

        if (whitelistOnly){
            require(whitelisted[msg.sender]);
        }

        if (tokensLeft < amount){
            amount = tokensLeft;
        }

        tokensLeft = tokensLeft - amount;
        reserve[msg.sender] += amount;
        committed[msg.sender] += msg.value;
        bought += amount;

        if (tokensLeft == 0){
            open = 2;
        }
    }

    function claim() public {
        require(open == 2, "Not closed");
        uint256 refund;
        uint256 tokens;
        tokens = reserve[msg.sender];
        committed[msg.sender] -= reserve[msg.sender] * price / 10 ** 18;
        reserve[msg.sender] = 0;
        refund = committed[msg.sender];
        committed[msg.sender] = 0;
        token.transfer(msg.sender, tokens);
        payable(msg.sender).transfer(refund);
    }

    fallback () external payable {
        if (open == 1 && block.timestamp >= start){
            bid(msg.value * 10 ** 18 / updateCurrentPrice());
        }
        else if (open == 2){
            require(msg.value == 0);
            claim();
            if (msg.sender == owner){
                withdraw();
            }
        }
        else{
            revert();
        }
    }

    function withdraw() public {
        require(hasClaimed == false, "Has been claimed");
        require(open == 2, "Not closed");

        hasClaimed = true;
        uint256 withdrawAmount = price * bought / 10**18;
        uint256 withdrawFee = withdrawAmount / 200;

        address payable alchemyRouter = IDutchAuctionFactory(factory).getRouter();

        // send a 0.5% fee to the router
        IAlchemyRouter(alchemyRouter).deposit{value: withdrawFee}();

        owner.transfer(withdrawAmount - withdrawFee);
        token.transfer(owner, tokensLeft);
    }
}

interface IDutchAuctionFactory {
    function getRouter() external view returns (address payable);
}


interface IAlchemyRouter {
    function deposit() external payable;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}