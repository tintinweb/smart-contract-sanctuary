pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract Games is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // BlindBox Basic
    Invite private inviteContract;
    ERC20 private macTokenContract;
    ERC20 private metTokenContract;
    address private officialAddress;
    bool private gameSwitchState;
    uint256 private gameStartTime;
    uint256 private gamesPayTotalAmountMac;
    uint256 private gamesPayTotalAmountMet;
    uint256 private gameJoinTotalCount;
    uint256 private gameRechargeCount;
    uint256 private gameOpenPayAmount;
    uint256 private gameMinPayAmount;

    // Account Info
    mapping(address => bool) private gameAccounts;

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _inviteContract, address _macTokenContract,address _metTokenContract, address _officialAddress);
    event SwitchState(address indexed _account, bool _gameSwitchState);
    event OpenPayAmount(address indexed _account, uint256 _gameOpenPayAmount, uint256 _gameMinPayAmount);
    event JoinGame(address indexed _account, uint256 _gameJoinTotalCount, uint256 _gamesPayTotalAmountMac, uint256 _gameOpenPayAmount);
    event Recharge(address indexed _account, uint256 _gameRechargeCount, uint256 _coinType, uint256 _rechargeAmount);

    // ================= Initial Value ===============

    constructor () public {
          inviteContract = Invite(0x785275beFcf3D606061252c5c976B79790cC9246);
          macTokenContract = ERC20(0xDF33E6c6eA9BE9A2F8fC18e898caCaFc82d3a414);
          metTokenContract = ERC20(0x2697dFb5BA8692C4aAb0b59C3504873A1F7e491F);
          officialAddress = address(0x8F04b966d6FA78D087004E8ef624421511FAc0a4);
          gameSwitchState = true;
          gameOpenPayAmount = 100 * 10 ** 18; // 100 coin
          gameMinPayAmount = 50 * 10 ** 18; // 50 coin
    }

    // ================= Box Operation  =================

    function joinGame() public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

        // Data validation
        require(gameSwitchState,"-> gameSwitchState: game has not started yet.");
        require(!gameAccountOf(msg.sender),"-> isJoin: account is exist.");
        require(macTokenContract.balanceOf(msg.sender)>=gameOpenPayAmount,"-> gameOpenPayAmount: Insufficient address token balance.");

        // Orders dispose
        gameJoinTotalCount += 1;// total number + 1
        gamesPayTotalAmountMac += gameOpenPayAmount;
        gameAccounts[msg.sender] = true;

        macTokenContract.safeTransferFrom(address(msg.sender), officialAddress, gameOpenPayAmount);// Transfer cuse to officialAddress
        emit JoinGame(msg.sender, gameJoinTotalCount, gamesPayTotalAmountMac, gameOpenPayAmount);// set log

        return true;// return result
    }

    function recharge(uint256 coinType,uint256 _rechargeAmount) public returns (bool) {
        // Data validation
        require(gameSwitchState,"-> gameSwitchState: game has not started yet.");
        require(gameAccountOf(msg.sender),"-> isJoin: account not exist.");
        require(_rechargeAmount>=gameMinPayAmount,"-> gameMinPayAmount: Need to be greater than the minimum recharge quantity.");

        if(coinType==1){
            require(macTokenContract.balanceOf(msg.sender)>=_rechargeAmount,"-> _rechargeAmount: Insufficient address token balance.");
            gamesPayTotalAmountMac += _rechargeAmount;
            macTokenContract.safeTransferFrom(address(msg.sender), officialAddress, _rechargeAmount);// Transfer cuse to officialAddress

        }else if(coinType==2){
            require(metTokenContract.balanceOf(msg.sender)>=_rechargeAmount,"-> _rechargeAmount: Insufficient address token balance.");
            gamesPayTotalAmountMet += _rechargeAmount;
            metTokenContract.safeTransferFrom(address(msg.sender), officialAddress, _rechargeAmount);// Transfer cuse to officialAddress
        }

        // Orders dispose
        gameRechargeCount += 1;// total number + 1
        emit Recharge(msg.sender, gameRechargeCount, coinType, _rechargeAmount);// set log

        return true;// return result
    }

    // ================= Contact Query  =====================

    function getGameBasic() public view returns (Invite InviteContract,ERC20 MacTokenContract,ERC20 MetTokenContract,address OfficialAddress,bool GameSwitchState,uint256 GameStartTime,
        uint256 GamesPayTotalAmountMac,uint256 GamesPayTotalAmountMet,uint256 GameMinPayAmount,uint256 GameJoinTotalCount,uint256 GameRechargeCount,uint256 GameOpenPayAmount) {
        return (inviteContract,macTokenContract,metTokenContract,officialAddress,gameSwitchState,gameStartTime,gamesPayTotalAmountMac,gamesPayTotalAmountMet,gameMinPayAmount,
          gameJoinTotalCount,gameRechargeCount,gameOpenPayAmount);
    }

    function gameAccountOf(address _account) public view returns (bool IsExist){
        return gameAccounts[_account];
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _inviteContract,address _macTokenContract,address _metTokenContract,address _officialAddress) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        macTokenContract = ERC20(_macTokenContract);
        metTokenContract = ERC20(_metTokenContract);
        officialAddress = _officialAddress;
        emit AddressList(msg.sender, _inviteContract, _macTokenContract, _metTokenContract, _officialAddress);
        return true;
    }

    function setGameSwitchState(bool _gameSwitchState) public onlyOwner returns (bool) {
        gameSwitchState = _gameSwitchState;
        if(gameStartTime==0&&_gameSwitchState){
            gameStartTime = block.timestamp;
        }
        emit SwitchState(msg.sender, _gameSwitchState);
        return true;
    }

    function setGameOpenPayAmount(uint256 _gameOpenPayAmount,uint256 _gameMinPayAmount) public onlyOwner returns (bool) {
        gameOpenPayAmount = _gameOpenPayAmount;
        gameMinPayAmount = _gameMinPayAmount;
        emit OpenPayAmount(msg.sender, _gameOpenPayAmount, _gameMinPayAmount);
        return true;
    }

}