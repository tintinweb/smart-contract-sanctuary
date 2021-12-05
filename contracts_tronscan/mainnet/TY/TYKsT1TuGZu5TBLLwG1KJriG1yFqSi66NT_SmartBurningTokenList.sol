//SourceUnit: SmartBurningTokenList.sol

pragma solidity 0.5.10;

contract SmartBurningTokenList {
    struct Token {
        address tokenAddress;
        uint256 burnAmount;
        uint256 burnRate;
        bool isExist;
    }
    
    address public governance;

    mapping (uint8 => Token) private tokens;

    event SetupToken(uint8 tokenIndex, address tokenAddress);
    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    function setupToken(uint8 _tokenIndex, address _tokenAddress, uint256 _burnAmount, uint256 _burnRate) public onlyGovernance returns(bool) {
        require(_tokenIndex > 0, "invalid index");

        tokens[_tokenIndex].isExist = true;
        tokens[_tokenIndex].tokenAddress = _tokenAddress;
        tokens[_tokenIndex].burnAmount = _burnAmount;
        tokens[_tokenIndex].burnRate = _burnRate;

        emit SetupToken(_tokenIndex, _tokenAddress);
        return true;
    }

    /**
    * @dev Allows the current governance to transfer control of the contract to a newGovernance.
    * @param newGovernance The address to transfer governance to.
    */
    function transferGovernance(address newGovernance) public onlyGovernance {
        require(newGovernance != address(0));
        emit GovernanceTransferred(governance, newGovernance);
        governance = newGovernance;
    }

    /**
    * @dev renounce Governance
    */
    function renounceGovernance() public onlyGovernance {
        governance = address(0);
        emit GovernanceTransferred(governance, address(0));
    }

    function tokenOf(uint8 _tokenIndex) public view returns(bool isExist, address tokenAddress, uint256 burnAmount, uint256 burnRate) {
        return (
            tokens[_tokenIndex].isExist,
            tokens[_tokenIndex].tokenAddress,
            tokens[_tokenIndex].burnAmount,
            tokens[_tokenIndex].burnRate
        );
    }
}