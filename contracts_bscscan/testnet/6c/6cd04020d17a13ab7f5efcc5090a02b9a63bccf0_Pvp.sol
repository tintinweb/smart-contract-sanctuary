/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-03-19
*/

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Pvp is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Game{
        string homeTeam;
        uint homeId;
        string guestTeam;
        uint guestId;
        uint roundNum;
        // draw => 1, homeTeam => 3, guestTeam => 0, start => 10, closed => 9
        uint gameResult;
        uint startTime;
        mapping(address => uint256) homeTeamList;
        mapping(address => uint256) guestTeamList;
        mapping(address => uint256) teamDrawList;
        uint256 homeTeamAccount;
        uint256 guestTeamAccount;
        uint256 teamDrawAccount;
    }

    Game[400] public gameList;
    uint num = 0;
//    address constant public manager = 0xb0Aa1F259B9231473B3E17333BD84B7F01Ba455a;
    address public manager = 0xb0Aa1F259B9231473B3E17333BD84B7F01Ba455a;
    IERC20 public token;
    IERC20 public rewardsToken;

    event Bet(address indexed from, uint id, uint result, uint256 value);
    event Claim(address indexed from, uint id, uint256 value);
    event UpdateRs(address indexed from, uint id, uint rs);

    constructor(IERC20 _token,IERC20 _rewardsToken) public {
        token = _token;
        rewardsToken = _rewardsToken;
    }

    function setManager(address _m) public onlyOwner{
        manager = _m;
    }

    function setToken(IERC20 _token) public onlyOwner{
        token = _token;
    }

    function setRewardsToken(IERC20 _rewardsToken) public onlyOwner{
        rewardsToken = _rewardsToken;
    }

    function AddGame(string memory _homeTeam, uint _homeId, string memory _guestTeam,
        uint _guestId, uint _round, uint _startTime) public onlyOwner {
        gameList[num] = Game({homeTeam: _homeTeam,
            homeId: _homeId,
            guestTeam: _guestTeam,
            guestId: _guestId,
            roundNum: _round,
            startTime: _startTime,
            gameResult: 10,
            homeTeamAccount: 0,
            guestTeamAccount: 0,
            teamDrawAccount: 0});
        num++;
    }

    function AddGames(string[] memory _homeTeams, uint[] memory _homeIds, string[] memory _guestTeams,
        uint[] memory _guestIds, uint[] memory _rounds, uint[] memory _startTimes) public onlyOwner {
        require(_homeTeams.length == _guestTeams.length && _guestTeams.length == _startTimes.length, "Record error");
        for(uint i = 0; i < _homeTeams.length; i++){
            AddGame(_homeTeams[i], _homeIds[i], _guestTeams[i], _guestIds[i], _rounds[i], _startTimes[i]);
        }
    }

    function updateRs(uint _id,uint _rs) public onlyOwner {
        require(block.timestamp > gameList[_id].startTime,"The purchase has not closed");
        require(gameList[_id].gameResult > 4, "The game is over");
        gameList[_id].gameResult = _rs;
        uint256 amount = 0;
        if(gameList[_id].gameResult == 1){
            amount = gameList[_id].guestTeamAccount.add(gameList[_id].homeTeamAccount);
        }
        if(gameList[_id].gameResult == 3){
           amount = gameList[_id].guestTeamAccount.add(gameList[_id].teamDrawAccount);
        }
        if(gameList[_id].gameResult == 0){
           amount = gameList[_id].homeTeamAccount.add(gameList[_id].teamDrawAccount);
        }
        token.safeTransfer(manager,amount.mul(10).div(100));
        emit UpdateRs(manager,_id,_rs);
    }

    function updateTime(uint _id,uint _time) public onlyOwner {
        require(gameList[_id].gameResult == 10,"The game is over");
        gameList[_id].startTime = _time;
    }

    function updateGame(uint _id,string memory _homeTeam, uint _homeId, string memory _guestTeam,
        uint _guestId, uint _round, uint _startTime) public onlyOwner{
        require(gameList[_id].gameResult == 10,"The game is over");
        gameList[_id].homeTeam = _homeTeam;
        gameList[_id].homeId = _homeId;
        gameList[_id].guestTeam = _guestTeam;
        gameList[_id].guestId = _guestId;
        gameList[_id].roundNum = _round;
        gameList[_id].startTime = _startTime;
    }

    function mintLpToken(uint256 amount) private {
        amount = amount.mul(10);
        require(amount > 0, "Pool: Amount is too small");
        rewardsToken.mint(msg.sender, amount);
    }

    function bet(uint _id,uint _rs,uint256 _amount) public {
        require(gameList[_id].gameResult == 10,"The purchase has been closed");
        require(gameList[_id].startTime > block.timestamp, "The purchase has been closed");
        if(_rs == 0){
            gameList[_id].guestTeamList[msg.sender] = gameList[_id].guestTeamList[msg.sender].add(_amount);
            gameList[_id].guestTeamAccount = gameList[_id].guestTeamAccount.add(_amount);
        }
        if(_rs == 1){
            gameList[_id].teamDrawList[msg.sender] = gameList[_id].teamDrawList[msg.sender].add(_amount);
            gameList[_id].teamDrawAccount = gameList[_id].teamDrawAccount.add(_amount);
        }
        if(_rs == 3){
            gameList[_id].homeTeamList[msg.sender] = gameList[_id].homeTeamList[msg.sender].add(_amount);
            gameList[_id].homeTeamAccount = gameList[_id].homeTeamAccount.add(_amount);
        }
        mintLpToken(_amount);
        token.safeTransferFrom(msg.sender,address (this),_amount);
        emit Bet(msg.sender, _id, _rs, _amount);
    }

    function claim(uint _id) public {
        require(gameList[_id].startTime < block.timestamp, "The purchase has not closed");
        require(gameList[_id].gameResult < 4, "The game is not over yet");
        require(gameList[_id].teamDrawList[msg.sender] > 0
            || gameList[_id].homeTeamList[msg.sender] > 0
            || gameList[_id].guestTeamList[msg.sender] > 0,"User account is Zero");
        uint256 amount = 0;
        if(gameList[_id].gameResult == 1){
            amount = claimTeamDraw(_id);
            gameList[_id].teamDrawList[msg.sender] = 0;
        }
        if(gameList[_id].gameResult == 3){
            amount = claimHomeTeam(_id);
            gameList[_id].homeTeamList[msg.sender] = 0;
        }
        if(gameList[_id].gameResult == 0){
            amount = claimGuestTeam(_id);
            gameList[_id].guestTeamList[msg.sender] = 0;
        }
        token.safeTransfer(msg.sender,amount);
        emit Claim(msg.sender, _id,amount);
    }

    function claimHomeTeam(uint _id) public view returns(uint256) {
        if(gameList[_id].homeTeamAccount == 0){
            return 0;
        }
        return gameList[_id].guestTeamAccount.add(gameList[_id].teamDrawAccount).mul(90)
            .mul(gameList[_id].homeTeamList[msg.sender]).div(gameList[_id].homeTeamAccount)
            .div(100).add(gameList[_id].homeTeamList[msg.sender]);
    }

    function claimGuestTeam(uint _id) public view returns(uint256) {
        if(gameList[_id].guestTeamAccount == 0){
            return 0;
        }
        return gameList[_id].homeTeamAccount.add(gameList[_id].teamDrawAccount).mul(90)
            .mul(gameList[_id].guestTeamList[msg.sender]).div(gameList[_id].guestTeamAccount).div(100)
            .add(gameList[_id].guestTeamList[msg.sender]);
    }

    function claimTeamDraw(uint _id) public view returns(uint256) {
        if(gameList[_id].teamDrawAccount == 0){
            return 0;
        }
        return gameList[_id].guestTeamAccount.add(gameList[_id].homeTeamAccount).mul(90)
            .mul(gameList[_id].teamDrawList[msg.sender]).div(gameList[_id].teamDrawAccount).div(100)
            .add(gameList[_id].teamDrawList[msg.sender]);
    }

//    rs[0]:id,rs[1]:homeId,rs[2]:guestId,rs[3]:roundNum,rs[4]:主队胜赔率,rs[5]:主队平赔率,rs[6]:主队负赔率,rs[7]:startTime,rs[8]:gameResult
    function getOddsPrice(uint _id) public view returns (uint256[] memory) {
        uint256[] memory rs = new uint256[](9);
        if(gameList[_id].homeTeamAccount > 0){
            rs[4] = gameList[_id].guestTeamAccount.add(gameList[_id].teamDrawAccount).mul(90).mul(1e18)
                .div(gameList[_id].homeTeamAccount).div(100).add(1e18);
        }
        if(gameList[_id].guestTeamAccount > 0){
            rs[6] = gameList[_id].homeTeamAccount.add(gameList[_id].teamDrawAccount).mul(90).mul(1e18)
                .div(gameList[_id].guestTeamAccount).div(100).add(1e18);
        }
        if(gameList[_id].teamDrawAccount > 0){
            rs[5] = gameList[_id].guestTeamAccount.add(gameList[_id].homeTeamAccount).mul(90).mul(1e18)
                .div(gameList[_id].teamDrawAccount).div(100).add(1e18);
        }
        rs[0] = _id;
        rs[1] = gameList[_id].homeId;
        rs[2] = gameList[_id].guestId;
        rs[3] = gameList[_id].roundNum;
        rs[7] = gameList[_id].startTime;
        rs[8] = gameList[_id].gameResult;
        return rs;
    }

    function getOddsPrices() public view returns (uint256[][] memory) {
        uint256[][] memory odds = new uint256[][](400);
        for(uint i = 0; i < 400; ++i){
            odds[i] = getOddsPrice(i);
        }
        return odds;
    }

    function getOddsPricesByRounds(uint _rounds) public view returns (uint256[][] memory) {
        uint256[][] memory odds = new uint256[][](10);
        uint256 j = 0;
        for(uint i = 0; i < gameList.length; ++i){
            if(gameList[i].roundNum == _rounds){
                odds[j] = getOddsPrice(i);
                j++;
            }
        }
        return odds;
    }
}