// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ITokenMarketRegistry.sol";
import "../../admin/interfaces/IGovWorldAdminRegistry.sol";
import "../../admin/interfaces/IGovWorldProtocolRegistry.sol";

contract TokenMarketRegistry is ITokenMarketRegistry {
    mapping(address => bool) public whitelistAddress;

    uint256 private loanActivateLimit;
    uint256 ltvPercentage = 125;

    address govAdminRegistry;
    address govWorldProtocolRegistry;

    constructor(address _govAdminRegistry, address _govWorldProtocolRegistry) {
        govAdminRegistry = _govAdminRegistry;
        govWorldProtocolRegistry = _govWorldProtocolRegistry;
    }

    modifier onlySuperAdmin(address _superAdmin) {
        require(
            IGovWorldAdminRegistry(govAdminRegistry).isSuperAdminAccess(
                msg.sender
            ),
            "GTM: Not a Gov Super Admin."
        );
        _;
    }

    function setloanActivateLimit(uint256 _loansLimit)
        public
        onlySuperAdmin(msg.sender)
    {
        require(_loansLimit > 0, "GTM: loanlimit error");
        loanActivateLimit = _loansLimit;
    }

    function getLoanActivateLimitt() external view override returns (uint256) {
        return loanActivateLimit;
    }

    function setLTVPercentage(uint256 _ltvPercentage)
        public
        onlySuperAdmin(msg.sender)
    {
        require(_ltvPercentage > 0, "GTM: percentage amount error");
        ltvPercentage = _ltvPercentage;
    }

    function getLTVPercentage() external view override returns (uint256) {
        return loanActivateLimit;
    }

    function setWhilelistAddress(address _lender, bool _value)
        public
        onlySuperAdmin(msg.sender)
    {
        require(_lender != address(0x0), "GTM: null address error");
        whitelistAddress[_lender] = _value;
    }

    function isWhitelistedForActivation(address _lender)
        external
        view
        override
        returns (bool)
    {
        return whitelistAddress[_lender];
    }

    function isSuperAdminAccess(address _wallet)
        external
        view
        override
        returns (bool)
    {
        return
            IGovWorldAdminRegistry(govAdminRegistry).isSuperAdminAccess(
                _wallet
            );
    }

    function isTokenApproved(address _token)
        external
        view
        override
        returns (bool)
    {
        return
            IGovWorldProtocolRegistry(govWorldProtocolRegistry).isTokenApproved(
                _token
            );
    }

    function getGovPlatformFee() external view override returns (uint256) {
        return
            IGovWorldProtocolRegistry(govWorldProtocolRegistry)
                .getGovPlatformFee();
    }

    /**
    @dev functiosn that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external pure override returns (uint256) {
        // APY Fee Formula
        return ((loanAmount * autosellAPY) / 10000 / 365) * loanterminDays;
    }

    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(
        uint256 _loanAmountInBorrowed,
        uint256 _apyOffer,
        uint256 _termsLengthInDays
    ) external pure override returns (uint256) {
        // APY Fee Formula
        return
            ((_loanAmountInBorrowed * _apyOffer) / 10000 / 365) *
            _termsLengthInDays;
    }

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        override
        returns (
            address,
            bool,
            uint256
        )
    {
        return
            IGovWorldProtocolRegistry(govWorldProtocolRegistry)
                .getSingleApproveTokenData(_tokenAddress);
    }

    function isSynthetticMintOn(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        return
            IGovWorldProtocolRegistry(govWorldProtocolRegistry)
                .isSynthetticMintOn(_tokenAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenMarketRegistry {
    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(
        uint256 _loanAmountInBorrowed,
        uint256 _apyOffer,
        uint256 _termsLengthInDays
    ) external returns (uint256);

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external returns (uint256);

    function getLoanActivateLimitt() external view returns (uint256);

    function getLTVPercentage() external view returns (uint256);

    function isWhitelistedForActivation(address) external returns (bool);

    function isSuperAdminAccess(address) external returns (bool);

    function isTokenApproved(address) external returns (bool);

    function getGovPlatformFee() external view returns (uint256);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSynthetticMintOn(address _token) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovWorldAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    function isAddGovAdminRole(address admin) external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum TokenType {
    ISDEX,
    ISELITE,
    ISVIP
}

// Token Market Data
struct Market {
    address dexRouter;
    bool isReversedLoan;
    uint256 tokenLimitPerReverseLoan;
    address gToken;
    bool isMint;
    TokenType tokenType;
}

interface IGovWorldProtocolRegistry {
    /** 
    @dev check function if Token Contract address is already added 
    @param _tokenAddress token address */
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool);

    function getUnearnedAPYPercentageForLender()
        external
        view
        returns (uint256);

    function getGovPlatformFee() external view returns (uint256);

    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getAdminWalletPercentage() external view returns (uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (Market memory);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSynthetticMintOn(address _token) external view returns (bool);

    function getTokenMarket() external view returns (address[] memory);

    function getAdminFeeWallet() external view returns (address);

    function getSingleTokenSps(address _tokenAddress)
        external
        view
        returns (address[] memory);

    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        returns (bool);
}