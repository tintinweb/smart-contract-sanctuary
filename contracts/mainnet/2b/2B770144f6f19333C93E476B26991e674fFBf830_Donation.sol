{{
  "language": "Solidity",
  "settings": {
    "evmVersion": "istanbul",
    "libraries": {},
    "metadata": {
      "bytecodeHash": "ipfs",
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": false,
      "runs": 200
    },
    "remappings": [],
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  },
  "sources": {
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.6.0;\n\n/**\n * @dev Interface of the ERC20 standard as defined in the EIP.\n */\ninterface IERC20 {\n    /**\n     * @dev Returns the amount of tokens in existence.\n     */\n    function totalSupply() external view returns (uint256);\n\n    /**\n     * @dev Returns the amount of tokens owned by `account`.\n     */\n    function balanceOf(address account) external view returns (uint256);\n\n    /**\n     * @dev Moves `amount` tokens from the caller's account to `recipient`.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transfer(address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Returns the remaining number of tokens that `spender` will be\n     * allowed to spend on behalf of `owner` through {transferFrom}. This is\n     * zero by default.\n     *\n     * This value changes when {approve} or {transferFrom} are called.\n     */\n    function allowance(address owner, address spender) external view returns (uint256);\n\n    /**\n     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * IMPORTANT: Beware that changing an allowance with this method brings the risk\n     * that someone may use both the old and the new allowance by unfortunate\n     * transaction ordering. One possible solution to mitigate this race\n     * condition is to first reduce the spender's allowance to 0 and set the\n     * desired value afterwards:\n     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729\n     *\n     * Emits an {Approval} event.\n     */\n    function approve(address spender, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Moves `amount` tokens from `sender` to `recipient` using the\n     * allowance mechanism. `amount` is then deducted from the caller's\n     * allowance.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Emitted when `value` tokens are moved from one account (`from`) to\n     * another (`to`).\n     *\n     * Note that `value` may be zero.\n     */\n    event Transfer(address indexed from, address indexed to, uint256 value);\n\n    /**\n     * @dev Emitted when the allowance of a `spender` for an `owner` is set by\n     * a call to {approve}. `value` is the new allowance.\n     */\n    event Approval(address indexed owner, address indexed spender, uint256 value);\n}\n"
    },
    "contracts/Donation.sol": {
      "content": "// SPDX-License-Identifier: MIT\r\npragma solidity ^0.6.0;\r\n\r\n\r\nimport {IERC20} from \"@openzeppelin/contracts/token/ERC20/IERC20.sol\";\r\n\r\n\r\ncontract Donation {\r\n    IERC20 public Token;\r\n    uint256 public start;\r\n    uint256 public finish;\r\n    address payable public ad1;\r\n    address payable public ad2;\r\n    address payable public ad3;\r\n    address payable public ad4;\r\n\r\n    constructor(\r\n        IERC20 Tokent,\r\n        address payable a1,\r\n        address payable a2,\r\n        address payable a3,\r\n        address payable a4\r\n    ) public {\r\n        Token = Tokent;\r\n        start = now;\r\n        ad1 = a1;\r\n        ad2 = a2;\r\n        ad3 = a3;\r\n        ad4 = a4;\r\n    }\r\n\r\n    receive() external payable {\r\nrequire (tbal >= getamout(msg.value));\r\n        tbal -= getamout(msg.value);\r\n        Token.transfer(\r\n            msg.sender,\r\n            (msg.value * 10 * (finish - start)) /\r\n                ((finish - start) - (now - start))\r\n        );\r\n    }\r\n\r\n    uint256 public bal;\r\n\r\n    function donate() public {\r\n        bal = address(this).balance;\r\n        _transfer(ad1, bal / 4);\r\n        _transfer(ad2, bal / 4);\r\n        _transfer(ad3, bal / 4);\r\n        _transfer(ad4, bal / 4);\r\n    }\r\n\r\n    function _transfer(address payable to, uint256 amount) internal {\r\n      (bool success,) = to.call{value: amount}(\"\");\r\n      require(success, \"Donation: Error transferring ether.\");\r\n    }\r\n\r\nfunction getamout(uint256 am) public view returns (uint256){\r\n       uint256 amout;\r\n       amout = (am * 10 * (finish - start)) /\r\n                ((finish - start) - (now - start));\r\n       return amout;\r\n}\r\nuint256 public tbal;\r\nfunction reset() public {\r\n        require (now >=finish);\r\n        start = now;\r\n        finish = now + 20 hours;\r\n        tap();\r\n        }\r\n\r\nfunction tap() internal {\r\n        tbal = Token.balanceOf(address(this)) / 100;\r\n    }\r\n}\r\n"
    }
  }
}}