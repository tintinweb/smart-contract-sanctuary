// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IMintableAndBurnableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./../interfaces/IERC20.sol";

library AmountNormalization {
    uint8 internal constant DECIMALS = 18;

    function normalizeAmount(IERC20 self, uint256 denormalizedAmount) internal view returns (uint256 normalizedAmount) {
        uint256 scale = 10**(DECIMALS - self.decimals());
        if (scale != 1) {
            return denormalizedAmount * scale;
        }
        return denormalizedAmount;
    }

    function denormalizeAmount(IERC20 self, uint256 normalizedAmount)
        internal
        view
        returns (uint256 denormalizedAmount)
    {
        uint256 scale = 10**(DECIMALS - self.decimals());
        if (scale != 1) {
            return normalizedAmount / scale;
        }
        return normalizedAmount;
    }
}

