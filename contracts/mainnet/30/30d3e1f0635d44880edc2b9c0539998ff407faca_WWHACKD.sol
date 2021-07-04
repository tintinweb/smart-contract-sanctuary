pragma solidity ^0.7.0;

abstract contract ERC20Interface {
    function balanceOf(address tokenOwner) virtual view public  returns (uint balance);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
}


contract WWHACKD {
    string public name     = "Wrapped WHACKD";
    string public symbol   = "WWACKD";
    uint8  public decimals = 18;
    ERC20Interface  public whackdContract   = ERC20Interface(address(0xCF8335727B776d190f9D15a54E6B9B9348439eEE));

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function deposit(uint dad) public {
        // transfer, crediting our observed balance difference
        uint balanceBefore = whackdContract.balanceOf(address(this));
        whackdContract.transferFrom(msg.sender, address(this), dad);
        uint balanceChange = whackdContract.balanceOf(address(this)) - balanceBefore;
        require((dad/2) <= balanceChange && balanceChange <= dad, "saved you from getting WHACKD. retry.");
        
        balanceOf[msg.sender] += balanceChange;
        emit Deposit(msg.sender, balanceChange);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        
        balanceOf[msg.sender] -= wad;
        uint balanceBefore = whackdContract.balanceOf(msg.sender);
        whackdContract.transfer(msg.sender, wad);
        uint balanceChange = whackdContract.balanceOf(msg.sender) - balanceBefore;
        require((wad/2) <= balanceChange, "saved you from getting WHACKD. retry.");
        
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return whackdContract.balanceOf(address(this));
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 3000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}