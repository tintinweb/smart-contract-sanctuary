//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IPiraRoyalty.sol";
import "./PiraAdminModifier.sol";

contract PiraRoyalty is IPiraRoyalty, PiraAdminModifier {
    mapping(string => RoyaltyRule) private _rules;
    mapping(address => mapping(uint256 => string)) private _itemRules; //TokenContract[TokenId][RuleId]

    constructor(address adminContractAddress)
        PiraAdminModifier(adminContractAddress)
    {}

    function setRoyaltyRule(
        string memory royaltyHash,
        uint256 firstSalePiraFee,
        uint256 piraFee,
        uint256 royaltyFee
    ) public override onlyAdmin returns (bool) {
        string memory empty = "";
        require(
            keccak256(bytes(royaltyHash)) != keccak256(bytes(empty)),
            "PiraRoyalty: royaltyHash must be a valid hash."
        );
        require(
            firstSalePiraFee >= 0,
            "PiraRoyalty: firstSalePiraFee must be a zero or positive value."
        );
        require(
            firstSalePiraFee <= 50,
            "PiraRoyalty: firstSalePiraFee must be less than or equals to 50."
        );
        require(
            piraFee >= 0,
            "PiraRoyalty: piraFee must be a zero or positive value."
        );
        require(
            piraFee <= 50,
            "PiraRoyalty: piraFee must be less than or equals to 50."
        );
        require(
            royaltyFee >= 0,
            "PiraRoyalty: royaltyFee must be a zero or positive value."
        );
        require(
            royaltyFee <= 50,
            "PiraRoyalty: royaltyFee must be less than or equals to 50."
        );

        _rules[royaltyHash] = RoyaltyRule(
            firstSalePiraFee,
            piraFee,
            royaltyFee,
            true
        );

        return true;
    }

    function setItemRoyaltyRule(
        address tokenContract,
        string memory royaltyHash,
        uint256[] memory tokenIds
    ) public override onlyAdmin returns (bool) {
        require(
            tokenContract != address(0),
            "PiraRoyalty: tokenContract must be a valid address."
        );
        string memory empty = "";
        require(
            keccak256(bytes(royaltyHash)) != keccak256(bytes(empty)),
            "PiraRoyalty: royaltyHash must be a valid hash."
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _itemRules[tokenContract][tokenIds[i]] = royaltyHash;
        }

        return true;
    }

    function getRoyaltyRule(string memory royaltyHash)
        public
        view
        override
        returns (RoyaltyRule memory)
    {
        string memory empty = "";
        require(
            keccak256(bytes(royaltyHash)) != keccak256(bytes(empty)),
            "PiraRoyalty: royaltyHash must be a valid hash."
        );
        return _rules[royaltyHash];
    }

    function getItemRoyaltyRuleDetails(address tokenContract, uint256 tokenId)
        public
        view
        override
        returns (RoyaltyRule memory)
    {
        require(
            tokenContract != address(0),
            "PiraRoyalty: tokenContract must be a valid address."
        );
        require(tokenId >= 0, "PiraNFT: tokenId must be a valid id.");

        return _rules[_itemRules[tokenContract][tokenId]];
    }

    function checkRoyaltyRule(string memory royaltyHash)
        public
        view
        override
        returns (bool)
    {
        string memory empty = "";
        require(
            keccak256(bytes(royaltyHash)) != keccak256(bytes(empty)),
            "PiraRoyalty: royaltyHash must be a valid hash."
        );
        return _rules[royaltyHash].exists;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IPiraUtil.sol";

interface IPiraRoyalty is IPiraUtil{

    function setRoyaltyRule(
        string memory royaltyHash,
        uint256 firstSalePiraFee,
        uint256 piraFree,
        uint256 royaltyFee
        ) external returns(bool);

    function setItemRoyaltyRule(
        address tokenContract,
        string memory royaltyHash,
        uint256[] memory tokenIds
    ) external returns(bool);

    function getRoyaltyRule(string memory royaltyHash) external view returns (RoyaltyRule memory);

    function getItemRoyaltyRuleDetails(
        address tokenContract,
        uint256 tokenId
    ) external view returns (RoyaltyRule memory);

    function checkRoyaltyRule(string memory royaltyHash) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IPiraAdmin.sol";

contract PiraAdminModifier {
    address _piraAdminContractAddress;

    constructor(address adminContract){
        _piraAdminContractAddress = adminContract;
    }

    modifier onlyAdmin {
        IPiraAdmin adminContract = IPiraAdmin(_piraAdminContractAddress);
        require(adminContract.isAdmin(msg.sender), "Only admins are allowed to call this method.");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPiraUtil {
        struct RoyaltyRule {
        uint256 firstSalePiraFee;
        uint256 piraFee;
        uint256 royaltyFee;
        bool exists;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPiraAdmin {

    function grant(address admin) external returns(bool);

    function revoke(address admin) external returns(bool);

    function isAdmin(address admin) external view returns(bool);

    function getAdmins() external view returns(address[] memory);
}