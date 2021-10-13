/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// File: contracts/IERC20.sol

pragma solidity 0.5.17;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

// File: contracts/AddressHelper.sol

pragma solidity 0.5.17;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library AddressHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferEther(address to, uint256 value) internal {
        (bool success, ) = to.call.value(value)(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    function isContract(address token) internal view returns (bool) {
        if (token == address(0x0)) {
            return false;
        }
        uint256 size;
        assembly {
            size := extcodesize(token)
        }
        return size > 0;
    }

    /**
     * @dev returns the address used within the protocol to identify ETH
     * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

// File: contracts/Faucet.sol

pragma solidity 0.5.17;



contract Faucet {
    using AddressHelper for address;

    mapping(address => uint256) public withdrawAuth;
    uint256 public period = 8400;

    IERC20[] public tokens;
    mapping(address => uint256) public tokensInfo;

    address public core;

    constructor() public {
        core = msg.sender;
    }

    function withdraw() public {
        require(msg.sender == tx.origin, "do not withdraw from contract");

        uint256 start = withdrawAuth[msg.sender];
        require(start + period < block.number, "Please wait");

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 per = tokensInfo[address(tokens[i])];
            if (per > 0) {
                if (tokens[i].balanceOf(address(this)) >= per) {
                    address token = address(tokens[i]);
                    address(tokens[i]).safeTransfer(msg.sender, per);

                    emit Withdraw(
                        msg.sender,
                        token,
                        tokensInfo[address(tokens[i])]
                    );
                }
            }
        }
        withdrawAuth[msg.sender] = block.number;
    }

    function setPer(address _token, uint256 _per) public onlyCore {
        require(tokensInfo[_token] > 0, "Not exist");
        tokensInfo[_token] = _per;
    }

    function addToken(IERC20 _token, uint256 _per) public onlyCore {
        require(tokensInfo[address(_token)] == 0, "Token exists");
        require(_per > 0, "per > 0");
        uint256 index = tokens.length++;
        tokens[index] = _token;
        tokensInfo[address(_token)] = _per;
        emit AddToken(address(_token), _per);
    }

    function setPeriod(uint256 _period) public onlyCore {
        period = _period;
        emit SetPeriod(_period);
    }

    function removeToken(IERC20 _token) public onlyCore {
        IERC20[] memory _tokens = tokens;
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (address(_tokens[i]) == address(_token)) {
                tokens[i] = tokens[_tokens.length - 1];
                delete tokens[_tokens.length - 1];
                delete tokensInfo[address(_token)];
                uint256 balance = _token.balanceOf(address(this));
                if (balance > 0) {
                    address(_token).safeTransfer(
                        core,
                        _token.balanceOf(address(this))
                    );
                }
                emit RemoveToken(address(_token));
                break;
            }
        }
    }

    function tokensLength() public view returns (uint256) {
        return tokens.length;
    }

    modifier onlyCore() {
        require(msg.sender == core, "Not Authorized, Only Core");
        _;
    }

    event AddToken(address _token, uint256 _per);

    event SetPer(address _token, uint256 _per);

    event Withdraw(address withdrawer, address token, uint256 amount);

    event RemoveToken(address _token);

    event SetPeriod(uint256 _period);
}