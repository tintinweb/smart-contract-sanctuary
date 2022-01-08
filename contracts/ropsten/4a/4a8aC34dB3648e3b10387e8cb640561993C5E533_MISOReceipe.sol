// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./interfaces/IERC20.sol";
import "./Utils/SafeTransfer.sol";

interface IMisoTokenFactory {
    function createToken(
        uint256 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address token);
}

interface IPointList {
    function deployPointList(
        address _listOwner,
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external payable returns (address pointList);
}

interface IMisoLauncher {
    function createLauncher(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address newLauncher);
}

interface IMisoMarket {
    function createMarket(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address newMarket);

    function setAuctionWallet(address payable _wallet) external;

    function addAdminRole(address _address) external;
}

contract MISOReceipe is SafeTransfer {
    IMisoTokenFactory public misoTokenFactory;
    IPointList public pointListFactory;
    IMisoLauncher public misoLauncher;
    IMisoMarket public misoMarket;
    address public factory;

    constructor(
        IMisoTokenFactory _misoTokenFactory,
        IPointList _pointListFactory,
        IMisoLauncher _misoLauncher,
        IMisoMarket _misoMarket,
        address _factory
    ) public {
        misoTokenFactory = _misoTokenFactory;
        pointListFactory = _pointListFactory;
        misoLauncher = _misoLauncher;
        misoMarket = _misoMarket;
        factory = _factory;
    }

    function prepareMiso(
        bytes memory tokenFactoryData,
        address[] memory _accounts,
        uint256[] memory _amounts,
        bytes memory marketData,
        bytes memory launcherData
    ) external payable {
        require(_accounts.length == _amounts.length, "!len");

        address token;
        uint256 totalSupply;
        {
            (
                uint256 _misoTokenFactoryTemplateId,
                string memory _name,
                string memory _symbol,
                uint256 _initialSupply
            ) = abi.decode(
                    tokenFactoryData,
                    (uint256, string, string, uint256)
                );

            token = misoTokenFactory.createToken(
                _misoTokenFactoryTemplateId,
                address(0),
                abi.encode(_name, _symbol, msg.sender, _initialSupply)
            );
            totalSupply = _initialSupply;
            IERC20(token).approve(address(misoMarket), _initialSupply);
            IERC20(token).approve(address(misoLauncher), _initialSupply);
        }

        address pointList;
        if (_accounts.length != 0) {
            pointList = pointListFactory.deployPointList(
                msg.sender,
                _accounts,
                _amounts
            );
        }

        address newMarket;

        uint256 tokenForSale;

        {
            (uint256 _marketTemplateId, bytes memory mData) = abi.decode(
                marketData,
                (uint256, bytes)
            );
            tokenForSale = abi.decode(mData, (uint256));
            newMarket = misoMarket.createMarket(
                _marketTemplateId,
                token,
                tokenForSale,
                address(0),
                abi.encodePacked(
                    abi.encode(address(misoMarket), token),
                    mData,
                    abi.encode(address(this), pointList, msg.sender)
                )
            );
        }



        address newLauncher;
        {
            (
                uint256 _launcherTemplateId,
                uint256 _liquidityPercent,
                uint256 _locktime
            ) = abi.decode(launcherData, (uint256, uint256, uint256));

            newLauncher = misoLauncher.createLauncher(
                _launcherTemplateId,
                token,
                tokenForSale,
                address(0),
                abi.encode(
                    newMarket,
                    factory,
                    msg.sender,
                    msg.sender,
                    _liquidityPercent,
                    _locktime
                )
            );
        }

        // Miso market has to give admin role to the user, since it's set to this contract initially
        // to allow the auction wallet to be set to launcher once it's been deployed
        IMisoMarket(newMarket).addAdminRole(msg.sender);

        // Have to set auction wallet to the new launcher address AFTER the market is created
        // new launcher address is casted to payable to satisfy interface.                                                                                                           
        IMisoMarket(newMarket).setAuctionWallet(payable(newLauncher));

        uint256 tokenBalanceRemaining = IERC20(token).balanceOf(address(this));
        if (tokenBalanceRemaining > 0) {
            // Approve this contract to send remaining tokens back to the user
            IERC20(token).approve(address(this), tokenBalanceRemaining);
            _safeTransferFrom(
                token,
                address(this),
                msg.sender,
                tokenBalanceRemaining
            );
        }
    }
}

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity 0.6.12;

contract SafeTransfer {

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Helper function to handle both ETH and ERC20 payments
    function _safeTokenPayment(
        address _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            _safeTransferETH(_to,_amount );
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }


    /// @dev Helper function to handle both ETH and ERC20 payments
    function _tokenPayment(
        address _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            _to.transfer(_amount);
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }


    /// @dev Transfer helper from UniswapV2 Router
    function _safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }


    /**
     * There are many non-compliant ERC20 tokens... this can handle most, adapted from UniSwap V2
     * Im trying to make it a habit to put external calls last (reentrancy)
     * You can put this in an internal function if you like.
     */
    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal virtual {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) =
            token.call(
                // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"))
                abi.encodeWithSelector(0xa9059cbb, to, amount)
            );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 Transfer failed
    }

    function _safeTransferFrom(
        address token,
        address from,
        uint256 amount
    ) internal virtual {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) =
            token.call(
                // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"))
                abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
            );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 TransferFrom failed
    }

    function _safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }


}