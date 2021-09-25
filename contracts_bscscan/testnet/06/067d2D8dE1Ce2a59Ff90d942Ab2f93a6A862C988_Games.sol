pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC721.sol";

contract Games is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC721 for ERC721;

    // BlindBox Basic
    ERC20 private cuseTokenContract;
    address private officialAddress;
    bool private gameSwitchState;
    uint256 private gameStartTime;
    uint256 private gamesPayTotalAmount;
    uint256 private gameJoinTotalCount;
    uint256 private gameOpenPayAmount;

    // Account Info
    mapping(address => bool) private gameAccounts;

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _cuseTokenContract, address _officialAddress);
    event SwitchState(address indexed _account, bool _gameSwitchState);
    event OpenPayAmount(address indexed _account, uint256 _gameOpenPayAmount);
    event JoinGame(address indexed _account, uint256 _gameJoinTotalCount, uint256 _gameOpenPayAmount);

    // ================= Initial Value ===============

    constructor () public {
          cuseTokenContract = ERC20(0x971f1EA8caa7eAC25246E58b59acbB7818F112D0);
          officialAddress = address(0xF92294D80Fa5B755dE0f95492065FBda6E45a4d9);
          gameSwitchState = true;
          gameOpenPayAmount = 1000 * 10 ** 18; // 1000 coin
    }

    // ================= Box Operation  =================

    function joinGame() public returns (bool) {
        // Data validation
        require(gameSwitchState,"-> gameSwitchState: game has not started yet.");
        require(!gameAccountOf(msg.sender),"-> isJoin: account is exist.");
        require(cuseTokenContract.balanceOf(msg.sender)>=gameOpenPayAmount,"-> gameOpenPayAmount: Insufficient address token balance.");

        // Orders dispose
        gameJoinTotalCount += 1;// total number + 1
        gameJoinTotalCount += gameOpenPayAmount;
        gameAccounts[msg.sender] = true;

        cuseTokenContract.safeTransferFrom(address(msg.sender), officialAddress, gameOpenPayAmount);// Transfer cuse to officialAddress
        emit JoinGame(msg.sender, gameJoinTotalCount, gameOpenPayAmount);// set log

        return true;// return result
    }

    // ================= Contact Query  =====================

    function getGameBasic() public view returns (ERC20 CuseTokenContract,address OfficialAddress,bool GameSwitchState,uint256 GameStartTime,
        uint256 GamesPayTotalAmount,uint256 GameJoinTotalCount,uint256 GameOpenPayAmount) {
        return (cuseTokenContract,officialAddress,gameSwitchState,gameStartTime,gamesPayTotalAmount,gameJoinTotalCount,gameOpenPayAmount);
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

    function setAddressList(address _cuseTokenContract,address _officialAddress) public onlyOwner returns (bool) {
        cuseTokenContract = ERC20(_cuseTokenContract);
        officialAddress = _officialAddress;
        emit AddressList(msg.sender, _cuseTokenContract, _officialAddress);
        return true;
    }

    function setGameSwitchState(bool _gameSwitchState) public onlyOwner returns (bool) {
        gameSwitchState = _gameSwitchState;
        if(gameStartTime==0){
            gameStartTime = block.timestamp;
        }
        emit SwitchState(msg.sender, _gameSwitchState);
        return true;
    }

    function setGameOpenPayAmount(uint256 _gameOpenPayAmount) public onlyOwner returns (bool) {
        gameOpenPayAmount = _gameOpenPayAmount;
        emit OpenPayAmount(msg.sender, _gameOpenPayAmount);
        return true;
    }

}