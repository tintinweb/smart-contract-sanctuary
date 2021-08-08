// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20Token.sol";

contract HDP is ERC20Token {

    string public constant NAME = "HEdpAY";
    string public constant SYMBOL = "Hdp\x2E\xD1\x84"; //"Hdp.ф";
    uint256 public constant CAP = 1000000000 * 1e18; //1 billion * 1e18 (decimals)

    function __HDP_init() external initializer {
        __ERC20Token_init(NAME, SYMBOL);
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function mint(address account, uint256 amount) external onlyOwner {
        require(ERC20Upgradeable.totalSupply() + amount <= CAP, "CAP exceeded");
        _mint(account, amount);
    }

    /**
     * @dev Function allows owner to return 
     * any tokens erroneously deposited into this contract 
     *@param _tokenAddress the address of the token contract 
     *@param _tokenAmount the amount of tokens for transferring
     *@param _tokenOwner the address of the token owner to which the tokens are sent
     */
    function transferAnyERC20Token(address _tokenAddress, uint _tokenAmount, address _tokenOwner) public onlyOwner returns (bool success) {
        return IERC20Upgradeable(_tokenAddress).transfer(_tokenOwner, _tokenAmount);
    }

    uint256[50] private __gap;
}