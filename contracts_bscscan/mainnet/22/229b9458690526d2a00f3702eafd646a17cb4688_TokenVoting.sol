pragma solidity ^0.7.6;
pragma abicoder v2;
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract TokenVoting is OwnableUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;

    event  WithdrawToken(uint amount);
    event  SetToken(address tokenaddr);
    event  Voting(string _Id, uint amount);
    event  CreateVotingTarget(string[] _Ids);
    event  SetVotinglimit (uint _newlimit);

    mapping(string => uint) public          tragetPoints;      // Id => points
    mapping(string => bool) public          tragetCreated;
    address public                          tokenaddr;
    uint public                             votinglimit;
    

    function __initialize(address _token, uint _votinglimit) external initializer {
        __Ownable_init();
        __Pausable_init();
        tokenaddr = _token;
        votinglimit = _votinglimit;
    }

    function createVotingTarget (string[] memory _Ids) public onlyOwner {
        for (uint i = 0; i < _Ids.length; i++) {
            require(!tragetCreated[_Ids[i]], "The Id is already occupied");
            tragetCreated[_Ids[i]] = true;
        }
        emit CreateVotingTarget(_Ids);
    }

    function voting (string memory _Id, uint amount) public whenNotPaused {
        require(tragetCreated[_Id], "This Id does not exist");
        require(amount >= votinglimit, "not reached voting limit");
        tragetPoints[_Id] = tragetPoints[_Id].add(amount);
        IERC20(tokenaddr).transferFrom(_msgSender(), address(this), amount);
        emit Voting(_Id, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setToken (address _newtoken) public onlyOwner {
        tokenaddr = _newtoken;
        emit SetToken(_newtoken);
    }

    function setVotinglimit (uint _newlimit) public onlyOwner {
        votinglimit = _newlimit;
        emit SetVotinglimit(_newlimit);
    }

    function withdrawToken(uint amount) public whenNotPaused onlyOwner {
        IERC20(tokenaddr).transfer(owner(), amount);
        emit WithdrawToken(amount);
    }
}