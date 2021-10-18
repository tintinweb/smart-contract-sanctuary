// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./settings.sol";


interface TS {
    function mint(address to, uint256 value) external;
}


contract TeamSaleBEP20 is Ownable {
    using SafeMath for uint256;

    TS public token;
    address payable public presale;

    uint256 public saleStart;
    uint256 public teamSale;

    uint256 public teamMinDepositBNB = 0 ether;
    uint256 public teamMaxDepositBNB = 5 ether;
    uint256 public teamMaxCap = 37.5 ether;
    uint256 public teamDepositBalance;

    mapping(address => uint256) public depositsTeam;
    mapping(address => uint256) public balanceMapTeam;
    mapping(address => bool) public depositStateTeam;

    constructor(
        TS _token
    ) {
        token = _token;
        //ahova kiküldje a befolyt $-t.
        presale = payable(0x5533719E8719328d5dFaADdc48f263a5cb7a538F);
        /*
        presaleEndTimestamp = block.timestamp.add(5 days + 1 hours + 30 minutes);
        */

        // ide majd konkrét időbéllyegzők kerülnek, a teszt erejéig jó így...
        saleStart = block.timestamp;
        teamSale = block.timestamp.add(5 minutes);
    }

    receive() payable external {
        depositTeamSale();
    }

    function depositTeamSale() public payable {
        require(block.timestamp >= saleStart && block.timestamp < teamSale, "presale is not active");
        require(teamDepositBalance.add(msg.value) <= teamMaxCap, "deposit limits reached");
        require(depositsTeam[msg.sender].add(msg.value) >= teamMinDepositBNB && depositsTeam[msg.sender].add(msg.value) <= teamMaxDepositBNB, "incorrect amount");

        uint256 teamSalePrice;
        teamSalePrice =  0.0000375 ether;  // 1 token / BNB price

        uint256 tokenAmount = msg.value.mul(1e18).div(teamSalePrice);
        //token.mint(msg.sender, tokenAmount);
        balanceMapTeam[msg.sender]=balanceMapTeam[msg.sender].add(tokenAmount);
        depositStateTeam[msg.sender]=true;
        teamDepositBalance = teamDepositBalance.add(msg.value);
        depositsTeam[msg.sender] = depositsTeam[msg.sender].add(msg.value);
        emit DepositedTeam(msg.sender, msg.value);
    }

    function releaseFundsTeamSale() external onlyOwner {
        //require(block.timestamp > teamSale || teamDepositBalance == teamMaxCap, "presale is active");
        presale.transfer(address(this).balance);
    }

    function withdrawTeamSale()public{
        //require(depositState[msg.sender]==false || getTeamTimelock()<block.timestamp);
        //require(depositStateTeam[msg.sender]);
        //depositStateTeam[msg.sender]=false;
      
        token.mint(msg.sender,balanceMapTeam[msg.sender]);
    }

    function recoverBEP20TeamSale(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IBEP20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit RecoveredTeam(tokenAddress, tokenAmount);
    }

    function getDepositAmountTeamSale() public view returns (uint256) {
        return teamDepositBalance;
    }

    function getLeftTimeAmount() public view returns (uint256) {
        if(block.timestamp > teamSale) {
            return 0;
        } else {
            return (teamSale - block.timestamp);
        }
    }

    event DepositedTeam(address indexed user, uint256 amount);
    event RecoveredTeam(address token, uint256 amount);
}