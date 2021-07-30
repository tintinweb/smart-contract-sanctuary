/**
 *Submitted for verification at polygonscan.com on 2021-07-30
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address spender, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address owner, address spender, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

contract PolyPenguin is ERC20 {
    string public constant name  = "PolyPenguin";
    string public constant symbol = "PENG";
    uint8 public constant decimals = 18;

    uint256 totalPengs = 250000 * (10 ** 18);
    
    address public currentGovernance;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    constructor() {
        currentGovernance = msg.sender;
        balances[msg.sender] = totalPengs;
        emit Transfer(address(0), msg.sender, totalPengs);
    }

    function totalSupply() public view override returns (uint256) {
        return totalPengs;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address spender, uint256 value) public override returns (bool) {
        require(value <= balances[msg.sender]);
        require(spender != address(0));

        balances[msg.sender] -= value;
        balances[spender] += value;

        emit Transfer(msg.sender, spender, value);
        return true;
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint256 tokens, bytes calldata data) external override returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function transferFrom(address owner, address spender, uint256 value) public override returns (bool) {
        require(value <= balances[owner]);
        require(value <= allowed[owner][msg.sender]);
        require(spender != address(0));

        balances[owner] -= value;
        balances[spender] += value;

        allowed[owner][msg.sender] -= value;

        emit Transfer(owner, spender, value);
        return true;
    }

    function updateGovernance(address newGovernance) external {
        require(msg.sender == currentGovernance);
        currentGovernance = newGovernance;
    }
    
    function mint(uint256 amount, address recipient) external {
        require(msg.sender == currentGovernance);
        if (amount > 0) {
            balances[recipient] += amount;
            totalPengs += amount;
            emit Transfer(address(0), recipient, amount);
        }
    }

    function burn(uint256 amount) external {
        if (amount > 0) {
            totalPengs -= amount;
            balances[msg.sender] -= amount;
            emit Transfer(msg.sender, address(0), amount);
        }
    }
}