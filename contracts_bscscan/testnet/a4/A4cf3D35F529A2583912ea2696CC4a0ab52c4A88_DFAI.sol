pragma solidity 0.5.17;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract DFAI is Context, ReentrancyGuard {
    using SafeMath for uint256;

    address private ownerAddress;

    // map using player address to upline
    mapping(address => string) players;
    address[] internal playerAccounts;

    struct Token {
        address tokenAddress;
        uint8 tokenDecimal;
    }

    // map using token symbol
    mapping(string => Token) tokens;
    address[] internal tokensAvailable;

    event Deposited(
        string upline,
        address indexed player,
        uint256 depositAmount,
        string _tokenSymbol
    );

    event withdrawRequest(address to, uint256 amount);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner {
        require(ownerAddress == msg.sender);
        _;
    }

    constructor() public {
        ownerAddress = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(ownerAddress, newOwner);
        ownerAddress = newOwner;
    }


    function setNewPlayer(address _address, string memory _upline) internal {
        players[_address] = _upline;

        playerAccounts.push(_address) - 1;
    }

    function getTokensAvailable() external view returns (address[] memory) {
        return tokensAvailable;
    }
    
    function getOwner() external view returns (address) {
        return ownerAddress;
    }
    
    function getPlayerUpline() external view returns (string memory) {
        return players[msg.sender];
    }

    function addNewToken(
        string memory _tokenSymbol,
        address _tokenAddress,
        uint8 _tokenDecimal

    ) public onlyOwner nonReentrant {
        Token storage token = tokens[_tokenSymbol];

        token.tokenAddress = _tokenAddress;
        token.tokenDecimal = _tokenDecimal;

        tokensAvailable.push(_tokenAddress) - 1;
    }

    function deposit(
        string memory _upline,
        uint256 _depositAmount,
        string memory _tokenSymbol
    ) public nonReentrant {
        Token storage token = tokens[_tokenSymbol];
        require(
            _depositAmount <= IERC20(token.tokenAddress).balanceOf(msg.sender)
        );

        IERC20(token.tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _depositAmount
        );

        bytes memory tempUplineCheck = bytes(players[msg.sender]); // Uses memory
        if (tempUplineCheck.length == 0) {
            setNewPlayer(msg.sender, _upline);
        }

        emit Deposited(_upline, msg.sender, _depositAmount, _tokenSymbol);
    }

    function withdraw(
        address _withdrawto,
        string memory _tokenSymbol,
        uint256 _withdrawAmount
    ) public onlyOwner nonReentrant {

        Token storage token = tokens[_tokenSymbol];
        IERC20(token.tokenAddress).transfer(_withdrawto, _withdrawAmount);
    }

    function tokenBalance(string calldata _tokenSymbol) external view returns (uint256) {
        Token storage token = tokens[_tokenSymbol];
        return IERC20(token.tokenAddress).balanceOf(address(this));
    }

}