/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.4.18;

contract WETH9 {
    string public name     = "PairX Ether";
    string public symbol   = "PETH";
    uint8  public decimals = 18;

    uint256 public totalPETH;
    uint256 public totalETH;
    uint256 public totalInterest;
    uint256 public usedETH;

    address private investAddr;
    address private interestAddr;

    event  Approval(address indexed src, address indexed guy, uint256 wad);
    event  Transfer(address indexed src, address indexed dst, uint256 wad);
    event  Deposit(address indexed dst, uint256 wad);
    event  Withdrawal(address indexed src, uint256 wad);

    mapping (address => uint256)                       public  balanceOf;
    mapping (address => mapping (address => uint256))  public  allowance;
    
    constructor(address _investAddr,address _interestAddr) public {
        require(_investAddr != _interestAddr);
        investAddr = _investAddr;
        interestAddr = _interestAddr;
        totalPETH = 0;
        totalETH = 0;
        totalInterest = 0;
        usedETH = 0;
    }

    function() public payable {
        deposit();
    }
    function deposit() public payable {
        if (msg.sender == investAddr) {
            require(usedETH >= msg.value);
            usedETH -= msg.value;
        } else if (msg.sender == interestAddr) {
            totalETH += msg.value;
            totalInterest += msg.value;
        } else if (totalETH > 0 && totalPETH > 0 && totalETH != totalPETH) {
            balanceOf[msg.sender] += msg.value * totalPETH / totalETH;
            totalPETH += msg.value * totalPETH / totalETH;
            totalETH += msg.value;
        } else {
            balanceOf[msg.sender] += msg.value;
            totalPETH += msg.value;
            totalETH += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint256 wad) public {
        uint256 ethNeed = 0;
        if (msg.sender == investAddr) {
            require(totalETH - usedETH >= wad);
            usedETH += wad;
        } else {
            if (totalPETH > 0) ethNeed = wad * totalETH / totalPETH;
            require(balanceOf[msg.sender] >= wad && totalETH - usedETH >= ethNeed);
            balanceOf[msg.sender] -= wad;
            totalPETH -= wad;
            totalETH -= ethNeed;
        }
        msg.sender.transfer(ethNeed);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return totalPETH;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad)
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

        emit Transfer(src, dst, wad);

        return true;
    }
}