/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;


interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimal() external view returns (uint);
    function totalSupply() external view returns (uint256);
    function balanceof(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    
    contract ERC20 is IERC20
    {
        mapping(address => uint) private _balances;

        mapping(address => mapping(address => uint)) private _allowances;

        uint private _totalSupply;

        string private _name;
        string private _symbol;
        uint private _decimals;
        address private owner;


        constructor(uint totalSupply_, string memory name_, string memory symbol_, uint decimals_) {

            _totalSupply = totalSupply_;
            _balances[msg.sender] = totalSupply_;
            _name = name_;
            _symbol = symbol_;
            _decimals = decimals_;
            owner = msg.sender; 

        } 
        modifier onlyowner{
            if(msg.sender != owner)
            {
                revert();
            
            }
            _;
        }

        function totalSupply() public override view returns(uint){
            return _totalSupply;
        }

        function balanceof(address account) public override view returns(uint)
        {
            return _balances[account];
        }

        function name() public override view returns(string memory){
            return _name;
        }

        function symbol() public override view returns(string memory){
            return _symbol;
        }
        function decimal() public override view returns(uint){
            return _decimals;
        }

        function transfer(address recipient, uint256 amount) public override returns (bool){

            require(amount <= _balances[msg.sender]);
            _balances[msg.sender] -= amount;
            _balances[recipient] += amount;
            emit Transfer(msg.sender, recipient, amount);
            return true;
        }

        function mint(uint256 quantity) public onlyowner returns(uint256)
        {
            _totalSupply += quantity;
            _balances[msg.sender] += quantity;
            return _totalSupply;
        }

        function burn(uint256 quantity) public returns (uint256){
        require(_balances[msg.sender] >= quantity);
        _totalSupply -= quantity;
        _balances[msg.sender] -= quantity;
        return _totalSupply;
    }


    function allowance(address holder, address spender) public view override returns (uint256){
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
         _approve(msg.sender, spender, amount);
         return true;
    }

     function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool){
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(_balances[sender] >= amount && currentAllowance >= amount);
        _balances[recipient] += amount;
        _balances[sender] -= amount;
       
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }


    function _approve(address holder, address spender, uint256 amount) internal  {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }




    }