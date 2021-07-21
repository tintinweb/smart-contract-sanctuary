/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.5.17;



// Part: AgentInterface

interface AgentInterface {
    function exec(address callee, bytes calldata payload) external returns (bytes memory);
    function exec(address callee, uint256 ETH_amount, bytes calldata payload) external returns (bytes memory);
}

// Part: IERC20

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function totalSupplyAt(uint blk_number) external view returns(uint);
    function balanceOf(address account) external view returns (uint256);
    function balanceOfAt(address accout, uint blk_number) external view returns (uint);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Part: Ownable

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// Part: PriceETHInterface

contract PriceETHInterface{
    function get_virtual_price() public view returns(uint256);
}

// Part: TokenClaimer

contract TokenClaimer{

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);
    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
  function _claimStdTokens(address _token, address payable to) internal {
        if (_token == address(0x0)) {
            to.transfer(address(this).balance);
            return;
        }
        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));

        (bool status,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(status, "call failed");
        emit ClaimedTokens(_token, to, balance);
  }
}

// Part: PoolBaseETH

contract PoolBaseETH is TokenClaimer, Ownable{
    string public name;

    // to be set by setAdmin()
    address public controller_addr;
    address public agent_addr;

    // to be init by sub_contract
    address public crv_pool_addr;
    address public crv_gauge_addr;
    address public crv_minter_addr;
    address public lp_token_addr;
    address public extra_yield_token_addr;

    uint256 public lp_balance;

    constructor() public {
        crv_minter_addr = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    }

    /* ----- d & w ----- */

    function deposit() public payable {        
        // msg.sender -ETH-> agent
        agent_addr.call.value(msg.value)("");
        deposit_to_pool(); // agent <-LP- -ETH-> crv_pool
        lp_balance = lp_balance + IERC20(lp_token_addr).balanceOf(agent_addr);
        deposit_to_gauge(); // agent -LP-> gauge
    }

    // deposit @_amount ETH from agent -> crv_pool
    // to be override by sub_contract
    function deposit_to_pool() internal;

    // deposit all agent's lp_token to gauage
    // since different pools use different lp_token, won't effect other pool using agent
    function deposit_to_gauge() internal {
        AgentInterface agent = AgentInterface(agent_addr);

        uint256 cur_lp_balance = IERC20(lp_token_addr).balanceOf(agent_addr);
        require(IERC20(lp_token_addr).balanceOf(agent_addr) != 0);
        agent.exec(lp_token_addr, abi.encodeWithSignature("approve(address,uint256)", crv_gauge_addr, 0));
        agent.exec(lp_token_addr, abi.encodeWithSignature("approve(address,uint256)", crv_gauge_addr, cur_lp_balance)); 
        agent.exec(crv_gauge_addr, abi.encodeWithSignature("deposit(uint256,address)", cur_lp_balance, agent_addr));

        require(IERC20(lp_token_addr).balanceOf(agent_addr) == 0, "PoolBaseETH: deposit_to_gauge: should have deposit all lp_token");
    }


    // @_amount: lp token amount
    function withdraw(uint256 _amount) public onlyAdmin {
        withdraw_from_gauge(_amount);
        require(IERC20(lp_token_addr).balanceOf(agent_addr) == _amount, "gauge: amount mismatch");
        withdraw_from_pool(_amount);
        lp_balance = lp_balance - _amount;
        AgentInterface(agent_addr).exec(
            msg.sender,
            address(agent_addr).balance,
            ""
        );
    }

    // with draw @_amount lp_token from gauge -> agent
    function withdraw_from_gauge(uint256 _amount) internal {
        require(_amount <= lp_balance, "PoolBaseETH: withdraw_from_gauge: insufficient lp_token in gauge");
        AgentInterface(agent_addr).exec(
            crv_gauge_addr, 
            abi.encodeWithSignature("withdraw(uint256)", _amount)
        );
    }

    // withdraw all avaliable lp_token from crv_pool -> agent
    // to be override by sub_contract
    function withdraw_from_pool(uint256 _amount) internal;
    
    /* ----- earn yield ----- */
    function claim_yield() external onlyAdmin {
        AgentInterface(agent_addr).exec(
            crv_minter_addr, 
            abi.encodeWithSignature("mint(address)", crv_gauge_addr)
        );
        claim_rewards();
    }

    function claim_rewards() internal;

    /* ----- admin ----- */
    modifier onlyAdmin(){
        require((controller_addr == msg.sender)||(agent_addr == msg.sender), "only controller or agent can call this");
        _;
    }
    function set_peers(address _controller, address _agent) public onlyOwner{
        controller_addr = _controller;
        agent_addr      = _agent;
    }
    function set_CRV(address _pool, address _gauge, address _minter, address _lp_token) public onlyOwner {
        crv_pool_addr   = _pool;
        crv_gauge_addr  = _gauge;
        crv_minter_addr = _minter;
        lp_token_addr   = _lp_token;
    }
    function claim_std_token(address _token, address payable to) public onlyOwner {
        _claimStdTokens(_token, to);
    }

    /* ----- view ----- */
    function get_lp_token_balance() public view returns(uint256) {
        return lp_balance;
    }
    function get_lp_token_addr() public view returns(address) {
        return lp_token_addr;
    }
    function get_extra_yield_token_addr() public view returns(address) {
        return extra_yield_token_addr;
    }
    function get_virtual_price() public view returns(uint256);

    /* ----- ETH ----- */
    function() external payable {
    }
}

// File: SethPool.sol

contract SethPool is PoolBaseETH{

    constructor() public{
        name = "Seth";
        crv_pool_addr = address(0xc5424B857f758E906013F3555Dad202e4bdB4567);
        lp_token_addr = address(0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c);
        crv_gauge_addr = address(0x3C0FFFF15EA30C35d7A85B85c0782D6c94e1d238);
    }

    function deposit_to_pool() internal {
        uint256 _amount = agent_addr.balance;
        uint256[2] memory uamounts = [_amount, 0];
        AgentInterface(agent_addr).exec(
            crv_pool_addr, 
            _amount,
            abi.encodeWithSignature("add_liquidity(uint256[2],uint256)", uamounts, 0)
        );
    }

    function withdraw_from_pool(uint256 _amount) internal{
        require(_amount <= lp_balance, "withdraw_from_pool: insufficient lp_token owned in crv_pool");
        require(crv_pool_addr.balance > 0, "money is 0");
        AgentInterface(agent_addr).exec(
            lp_token_addr, 
            abi.encodeWithSignature("approve(address,uint256)", crv_pool_addr, _amount)
        );
        AgentInterface(agent_addr).exec(
            crv_pool_addr, 
            abi.encodeWithSignature("remove_liquidity_one_coin(uint256,int128,uint256)", _amount, 0, 0)
        );
    }

    function claim_rewards() internal {
        // pass: no rewards
    } 

    function get_virtual_price() public view returns(uint256){
        return PriceETHInterface(crv_pool_addr).get_virtual_price();
    }
}