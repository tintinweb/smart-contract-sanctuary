/**
 *Submitted for verification at Etherscan.io on 2020-06-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.7.0;

interface TokenInterface {
    function invest(address investor) payable external returns(bool);
    function win(address investor, uint _tokens) external returns(bool);
}

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function transfer(address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
}

contract Token is ERC20Interface {
    string public name = "DEVILSDRAGON";
    string public symbol = "DDGN";
    uint public decimals = 18;
    uint tokenPrice = 0.001 ether;

    uint public supply;

    address public founder;
    address public team;
    address public reserved;
    address public ecosystem;
    address public dev_team;
    address public crowdsale;
    address public developer;

    address public manager;
    address payable public deposit;
    address public cinema;

    mapping(address => uint) public balances;

    modifier isManager(){
        require(msg.sender == manager, 'Caller is not manager');
        _;
    }

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Invest(address investor, uint value, uint tokens);

    constructor(address payable _deposit, address _founder, address _team, address _reserved, address _ecosystem, address _dev_team, address _crowdsale, address _developer) public {
        manager = msg.sender;
        supply = 180000000 * (10 ** decimals);
        founder = _founder;
        deposit = _deposit;
        balances[founder] = supply * 59 / 100; // 59%
        team = _team;
        balances[team] = supply * 9 / 100; // 9%
        reserved = _reserved;
        balances[reserved] = supply * 3 / 50; // 6%
        ecosystem = _ecosystem;
        balances[ecosystem] = supply * 9 / 50; // 18%
        dev_team = _dev_team;
        balances[dev_team] = supply / 50; // 2%
        crowdsale = _crowdsale;
        balances[crowdsale] = supply / 20; // 5%
        developer = _developer;
        balances[developer] = supply / 100; // 1%
    }

    receive() payable external {
        invest(msg.sender);
    }

    function changeDeposit(address payable newDeposit) public isManager {
        deposit = newDeposit;
    }

    function changeManager(address newManager) public isManager {
        manager = newManager;
    }

    function totalSupply() public view override returns (uint) {
        return supply;
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
         return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public virtual override returns (bool success) {
         require(balances[msg.sender] >= tokens && tokens > 0);

         balances[to] += tokens;
         balances[msg.sender] -= tokens;
         emit Transfer(msg.sender, to, tokens);
         return true;
     }

    function invest(address investor) payable public returns(bool) {
        uint tokens = msg.value / tokenPrice * (10 ** decimals);
        require(balances[founder] >= tokens && tokens > 0, 'No tokens left');

        balances[investor] += tokens;
        balances[founder] -= tokens;

        deposit.transfer(msg.value);

        //emit event
        emit Invest(investor, msg.value, tokens);

        return true;
    }

    function changeCinema(address _cinema) public isManager {
        cinema = _cinema;
    }

    function win(address investor, uint _tokens) public returns(bool) {
        require(msg.sender == cinema, 'Wrong sender');
        uint tokens = _tokens * (10 ** decimals);
        require(balances[founder] >= tokens && tokens > 0, 'No tokens left');

        balances[investor] += tokens;
        balances[founder] -= tokens;

        emit Transfer(founder, investor, tokens);

        return true;
    }
}