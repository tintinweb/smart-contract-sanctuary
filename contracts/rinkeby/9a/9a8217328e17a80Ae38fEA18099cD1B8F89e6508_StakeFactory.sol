// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {IStakeTONFactory} from "../interfaces/IStakeTONFactory.sol";
import {
    IStakeForStableCoinFactory
} from "../interfaces/IStakeForStableCoinFactory.sol";
import {IStake1Vault} from "../interfaces/IStake1Vault.sol";

contract StakeFactory {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    address public stakeTONFactory;
    address public stakeStableCoinFactory;

    constructor(address _stakeTONFactory, address _stableFactory) {
        require(
            _stakeTONFactory != address(0) && _stableFactory != address(0),
            "StakeFactory: init fail"
        );
        stakeTONFactory = _stakeTONFactory;
        stakeStableCoinFactory = _stableFactory;
    }

    function deploy(
        uint256 _pahse,
        address _vault,
        address _token,
        address _paytoken,
        uint256 _period,
        address[4] memory tokamakAddr
    ) public returns (address) {
        require(_vault != address(0), "StakeFactory: deploy init fail");

        IStake1Vault vault = IStake1Vault(_vault);
        uint256 saleStart = vault.saleStartBlock();
        uint256 stakeStart = vault.stakeStartBlock();
        uint256 stakeType = vault.stakeType();

        require(
            saleStart < stakeStart && stakeStart > 0,
            "StakeFactory: start error"
        );

        if (stakeType <= 1) {
            require(
                stakeTONFactory != address(0),
                "StakeFactory: stakeTONFactory zero"
            );

            return
                IStakeTONFactory(stakeTONFactory).deploy(
                    _pahse,
                    _vault,
                    _token,
                    _paytoken,
                    _period,
                    tokamakAddr,
                    msg.sender
                );
        } else if (stakeType == 2) {
            require(
                stakeStableCoinFactory != address(0),
                "StakeFactory: stakeStableCoinFactory zero"
            );

            return
                IStakeForStableCoinFactory(stakeStableCoinFactory).deploy(
                    _pahse,
                    _vault,
                    _token,
                    _paytoken,
                    _period,
                    msg.sender
                );
        }

        return address(0);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeTONFactory {
    function deploy(
        uint256 _pahse,
        address _vault,
        address _token,
        address _paytoken,
        uint256 _period,
        address[4] memory tokamakAddr,
        address _owner
    ) external returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeForStableCoinFactory {
    function deploy(
        uint256 _pahse,
        address _vault,
        address _token,
        address _paytoken,
        uint256 _period,
        address _owner
    ) external returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;
import "../libraries/LibTokenStake1.sol";

interface IStake1Vault {
    function initialize(
        address _fld,
        address _paytoken,
        uint256 _cap,
        uint256 _saleStartBlcok,
        uint256 _stakeStartBlcok
    ) external;

    /// @dev Sets the FLD address
    function setFLD(address _ton) external;

    /// @dev Changes the cap of vault.
    function changeCap(uint256 _cap) external;

    function changeOrderedEndBlocks(uint256[] memory _ordered) external;

    function addSubVaultOfStake(
        string memory _name,
        address stakeContract,
        uint256 periodBlocks
    ) external;

    function closeSale() external;

    function claim(address _to, uint256 _amount) external returns (bool);

    function canClaim(address _to, uint256 _amount)
        external
        view
        returns (uint256);

    function totalRewardAmount(address _account)
        external
        view
        returns (uint256);

    function stakeAddressesAll() external view returns (address[] memory);

    function orderedEndBlocksAll() external view returns (uint256[] memory);

    function fld() external view returns (address);

    function paytoken() external view returns (address);

    function cap() external view returns (uint256);

    function stakeType() external view returns (uint256);

    function defiAddr() external view returns (address);

    function saleStartBlock() external view returns (uint256);

    function stakeStartBlock() external view returns (uint256);

    function stakeEndBlock() external view returns (uint256);

    function blockTotalReward() external view returns (uint256);

    function saleClosed() external view returns (bool);

    function stakeEndBlockTotal(uint256 endblock)
        external
        view
        returns (uint256 totalStakedAmount);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

library LibTokenStake1 {
    struct StakeInfo {
        string name;
        uint256 startBlcok;
        uint256 endBlock;
        uint256 balance;
        uint256 totalRewardAmount;
        uint256 claimRewardAmount;
    }

    struct StakedAmount {
        uint256 amount;
        uint256 claimedBlock;
        uint256 claimedAmount;
        uint256 releasedBlock;
        uint256 releasedAmount;
        bool released;
    }

    struct StakedAmountForSFLD {
        uint256 amount;
        uint256 startBlock;
        uint256 periodBlock;
        uint256 rewardPerBlock;
        uint256 claimedBlock;
        uint256 claimedAmount;
        uint256 releasedBlock;
        uint256 releasedAmount;
    }
}

