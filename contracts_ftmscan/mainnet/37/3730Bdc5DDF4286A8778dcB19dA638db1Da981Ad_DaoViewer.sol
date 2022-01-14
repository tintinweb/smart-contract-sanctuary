//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IFactory.sol";
import "../interfaces/IDao.sol";
import "../interfaces/ILP.sol";
import "../interfaces/IShop.sol";

contract DaoViewer {
    struct DaoInfo {
        address dao;
        string daoName;
        string daoSymbol;
        address lp;
        string lpName;
        string lpSymbol;
    }

    function getDao(address _dao) public view returns (DaoInfo memory) {
        address lp = IDao(_dao).lp();

        if (lp == address(0)) {
            return
                DaoInfo({
                    dao: _dao,
                    daoName: IDao(_dao).name(),
                    daoSymbol: IDao(_dao).symbol(),
                    lp: address(0),
                    lpName: "",
                    lpSymbol: ""
                });
        }

        return
            DaoInfo({
                dao: _dao,
                daoName: IDao(_dao).name(),
                daoSymbol: IDao(_dao).symbol(),
                lp: lp,
                lpName: ILP(lp).name(),
                lpSymbol: ILP(lp).symbol()
            });
    }

    function getDaos(address _factory) public view returns (DaoInfo[] memory) {
        address[] memory _daosRaw = IFactory(_factory).getDaos();

        DaoInfo[] memory _daos = new DaoInfo[](_daosRaw.length);

        if (_daosRaw.length == 0) {
            return new DaoInfo[](0);
        } else {
            for (uint256 i = 0; i < _daosRaw.length; i++) {
                _daos[i] = getDao(_daosRaw[i]);
            }

            return _daos;
        }
    }

    function userDaos(address _user, address _factory)
        external
        view
        returns (DaoInfo[] memory)
    {
        DaoInfo[] memory _daos = getDaos(_factory);

        if (_daos.length == 0) {
            return new DaoInfo[](0);
        } else {
            DaoInfo[] memory _userDaos = new DaoInfo[](_daos.length);

            for (uint256 i = 0; i < _daos.length; i++) {
                if (IERC20Metadata(_daos[i].dao).balanceOf(_user) > 0) {
                    _userDaos[i] = _daos[i];
                }
            }

            return _userDaos;
        }
    }

    function getShare(address _dao, address[] memory _users)
        external
        view
        returns (
            uint256 share,
            uint256 totalSupply,
            uint8 quorum
        )
    {
        quorum = IDao(_dao).quorum();
        totalSupply = IERC20Metadata(_dao).totalSupply();

        if (_users.length == 0) {
            return (0, totalSupply, quorum);
        }

        share = 0;

        for (uint256 i = 0; i < _users.length; i++) {
            share += IERC20Metadata(_dao).balanceOf(_users[i]);
        }

        return (share, totalSupply, quorum);
    }

    function getShares(address _dao, address[][] memory _users)
        external
        view
        returns (
            uint256[] memory shares,
            uint256 totalSupply,
            uint8 quorum
        )
    {
        quorum = IDao(_dao).quorum();
        totalSupply = IERC20Metadata(_dao).totalSupply();

        shares = new uint256[](_users.length);

        for (uint256 i = 0; i < _users.length; i++) {
            if (_users[i].length == 0) {
                shares[i] = 0;
            } else {
                uint256 share = 0;

                for (uint256 j = 0; j < _users[i].length; j++) {
                    share += IERC20Metadata(_dao).balanceOf(_users[i][j]);
                }

                shares[i] = share;
            }
        }

        return (shares, totalSupply, quorum);
    }

    function balances(address[] memory users, address[] memory tokens)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory addrBalances = new uint256[](
            tokens.length * users.length
        );

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 addrIdx = j + tokens.length * i;

                if (tokens[j] != address(0x0)) {
                    addrBalances[addrIdx] = IERC20Metadata(tokens[j]).balanceOf(
                        users[i]
                    );
                } else {
                    addrBalances[addrIdx] = users[i].balance;
                }
            }
        }

        return addrBalances;
    }

    function getHashStatuses(address _dao, bytes32[] memory _txHashes)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory hashStatuses = new bool[](_txHashes.length);

        for (uint256 i = 0; i < _txHashes.length; i++) {
            hashStatuses[i] = IDao(_dao).executedTx(_txHashes[i]);
        }

        return hashStatuses;
    }

    struct DaoConfiguration {
        bool gtMintable;
        bool gtBurnable;
        address lpAddress;
        bool lpMintable;
        bool lpBurnable;
        bool lpMintableStatusFrozen;
        bool lpBurnableStatusFrozen;
        uint256 permittedLength;
        uint256 adaptersLength;
        uint256 monthlyCost;
        uint256 numberOfPrivateOffers;
    }

    function getDaoConfiguration(address _factory, address _dao)
        external
        view
        returns (DaoConfiguration memory)
    {
        address lp = IDao(_dao).lp();

        if (lp == address(0)) {
            return
                DaoConfiguration({
                    gtMintable: IDao(_dao).mintable(),
                    gtBurnable: IDao(_dao).burnable(),
                    lpAddress: address(0),
                    lpMintable: false,
                    lpBurnable: false,
                    lpMintableStatusFrozen: false,
                    lpBurnableStatusFrozen: false,
                    permittedLength: IDao(_dao).numberOfPermitted(),
                    adaptersLength: IDao(_dao).numberOfAdapters(),
                    monthlyCost: IFactory(_factory).monthlyCost(),
                    numberOfPrivateOffers: 0
                });
        } else {
            return
                DaoConfiguration({
                    gtMintable: IDao(_dao).mintable(),
                    gtBurnable: IDao(_dao).burnable(),
                    lpAddress: lp,
                    lpMintable: ILP(lp).mintable(),
                    lpBurnable: ILP(lp).burnable(),
                    lpMintableStatusFrozen: ILP(lp).mintableStatusFrozen(),
                    lpBurnableStatusFrozen: ILP(lp).burnableStatusFrozen(),
                    permittedLength: IDao(_dao).numberOfPermitted(),
                    adaptersLength: IDao(_dao).numberOfAdapters(),
                    monthlyCost: IFactory(_factory).monthlyCost(),
                    numberOfPrivateOffers: IShop(IFactory(_factory).shop())
                        .numberOfPrivateOffers(_dao)
                });
        }
    }

    function getInvestInfo(address _factory)
        external
        view
        returns (
            DaoInfo[] memory,
            IShop.PublicOffer[] memory,
            string[] memory,
            uint8[] memory,
            uint256[] memory
        )
    {
        DaoInfo[] memory daos = getDaos(_factory);

        uint256 daosLength = daos.length;

        if (daosLength == 0) {
            return (
                new DaoInfo[](0),
                new IShop.PublicOffer[](0),
                new string[](0),
                new uint8[](0),
                new uint256[](0)
            );
        }

        IShop.PublicOffer[] memory publicOffers = new IShop.PublicOffer[](
            daosLength
        );

        for (uint256 i = 0; i < daosLength; i++) {
            publicOffers[i] = IShop(IFactory(_factory).shop()).publicOffers(
                daos[i].dao
            );
        }

        string[] memory symbols = new string[](daosLength);
        uint8[] memory decimals = new uint8[](daosLength);

        for (uint256 i = 0; i < daosLength; i++) {
            if (publicOffers[i].currency != address(0)) {
                try IERC20Metadata(publicOffers[i].currency).symbol() returns (
                    string memory s
                ) {
                    symbols[i] = s;
                } catch {}

                try
                    IERC20Metadata(publicOffers[i].currency).decimals()
                returns (uint8 d) {
                    decimals[i] = d;
                } catch {}
            }
        }

        uint256[] memory numberOfPrivateOffers = new uint256[](daosLength);

        for (uint256 i = 0; i < daosLength; i++) {
            numberOfPrivateOffers[i] = IShop(IFactory(_factory).shop())
                .numberOfPrivateOffers(daos[i].dao);
        }

        return (daos, publicOffers, symbols, decimals, numberOfPrivateOffers);
    }

    function getPrivateOffersInfo(address _factory)
        external
        view
        returns (
            DaoInfo[] memory,
            uint256[] memory,
            IShop.PrivateOffer[] memory,
            string[] memory,
            uint8[] memory
        )
    {
        DaoInfo[] memory daos = getDaos(_factory);

        uint256 daosLength = daos.length;

        if (daosLength == 0) {
            return (
                new DaoInfo[](0),
                new uint256[](0),
                new IShop.PrivateOffer[](0),
                new string[](0),
                new uint8[](0)
            );
        }

        uint256[] memory totalPrivateOffers = new uint256[](daosLength);

        uint256 privateOffersLength = 0;

        IShop shop = IShop(IFactory(_factory).shop());

        for (uint256 i = 0; i < daosLength; i++) {
            uint256 numberOfPrivateOffers = shop.numberOfPrivateOffers(
                daos[i].dao
            );

            totalPrivateOffers[i] = numberOfPrivateOffers;

            privateOffersLength += numberOfPrivateOffers;
        }

        IShop.PrivateOffer[] memory privateOffers = new IShop.PrivateOffer[](
            privateOffersLength
        );

        string[] memory symbols = new string[](privateOffersLength);

        uint8[] memory decimals = new uint8[](privateOffersLength);

        uint256 indexCounter = 0;

        for (uint256 i = 0; i < daosLength; i++) {
            for (uint256 j = 0; j < totalPrivateOffers[i]; j++) {
                IShop.PrivateOffer memory privateOffer = shop.privateOffers(
                    daos[i].dao,
                    j
                );

                privateOffers[indexCounter] = privateOffer;

                try IERC20Metadata(privateOffer.currency).symbol() returns (
                    string memory s
                ) {
                    symbols[indexCounter] = s;
                } catch {}

                try IERC20Metadata(privateOffer.currency).decimals() returns (
                    uint8 d
                ) {
                    decimals[indexCounter] = d;
                } catch {}

                indexCounter++;
            }
        }

        return (daos, totalPrivateOffers, privateOffers, symbols, decimals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IFactory {
    function getDaos() external view returns (address[] memory);

    function shop() external view returns (address);

    function monthlyCost() external view returns (uint256);

    function subscriptions(address _dao) external view returns (uint256);

    function containsDao(address _dao) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IDao {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function lp() external view returns (address);

    function burnLp(
        address _recipient,
        uint256 _share,
        address[] memory _tokens,
        address[] memory _adapters,
        address[] memory _pools
    ) external returns (bool);

    function setLp(address _lp) external returns (bool);

    function quorum() external view returns (uint8);

    function executedTx(bytes32 _txHash) external view returns (bool);

    function mintable() external view returns (bool);

    function burnable() external view returns (bool);

    function numberOfPermitted() external view returns (uint256);

    function numberOfAdapters() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ILP {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function burn(address _to, uint256 _amount) external returns (bool);

    function mint(address _to, uint256 _amount) external returns (bool);

    function mintable() external view returns (bool);

    function burnable() external view returns (bool);

    function mintableStatusFrozen() external view returns (bool);

    function burnableStatusFrozen() external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IShop {
    struct PublicOffer {
        bool isActive;
        address currency;
        uint256 rate;
    }

    function publicOffers(address _dao)
        external
        view
        returns (PublicOffer memory);

    struct PrivateOffer {
        bool isActive;
        address recipient;
        address currency;
        uint256 currencyAmount;
        uint256 lpAmount;
    }

    function privateOffers(address _dao, uint256 _index)
        external
        view
        returns (PrivateOffer memory);

    function numberOfPrivateOffers(address _dao)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}