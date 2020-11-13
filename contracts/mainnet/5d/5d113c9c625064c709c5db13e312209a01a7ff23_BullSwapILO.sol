// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface BullSwapToken {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

	function balanceOf(address) external view returns(uint256);
    function transfer(address _to, uint256 _value) external;
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function burn(uint256 _value) external returns (bool success);
	function freeze(uint256 _value) external returns (bool success);
	function unfreeze(uint256 _value) external returns (bool success);
	function withdrawEther(uint256 amount) external;
}

interface IERC20 {
	function balanceOf(address) external view returns(uint256);
    function transfer(address _to, uint256 _value) external;
}

contract BullSwapILO {
    uint256 public tokenPerETH;
    uint256 public discountTokenPerETH;
    address public token;
    mapping(address => uint256) balances;
    mapping(address => bool) public discount;

    address payable private owner;

    constructor(address _token) public {
        owner = msg.sender;
        token = _token;
    }

    function requireOwner() private view {
        require(msg.sender == owner, "Bullswap ILO: require owner address");
    }
    
    function setDiscount(address payable _address) public {
        requireOwner();
        discount[_address] = true;
    }
    
     function unSetdiscount(address payable _address) public {
        requireOwner();
        discount[_address] = false;
    }

    function start(uint256 _tokenPerETH, uint256 _discountTokenPerETH) public {
        requireOwner();
        tokenPerETH = _tokenPerETH;
        discountTokenPerETH = _discountTokenPerETH;
    }

    function stop() public {
        requireOwner();
        uint256 balance = forSale();
        BullSwapToken t = BullSwapToken(token);
        t.burn(balance);
    }

    function withdrawal() public {
        requireOwner();
        owner.transfer(address(this).balance);
    }
    
    function getToken(address _token) public {
        requireOwner();
        IERC20 t = IERC20(_token);
        t.transfer(owner, t.balanceOf(address(this)));
    }

    function forSale() public view returns (uint256) {
        BullSwapToken t = BullSwapToken(token);
        uint256 balance = t.balanceOf(address(this));
        return balance;
    }

    receive() external payable {
        uint256 currentTokenPerETH = tokenPerETH;
        if (discount[msg.sender]) {
            // sale off
            currentTokenPerETH = discountTokenPerETH;
        }
        
        uint256 tokenAmount = msg.value * currentTokenPerETH;
        uint256 balance = forSale();
        require(balance >= tokenAmount, "Bullswap ILO: not enough token for sale");
        BullSwapToken t = BullSwapToken(token);
        t.transfer(msg.sender, tokenAmount);
        balances[msg.sender] += tokenAmount;
    }
}