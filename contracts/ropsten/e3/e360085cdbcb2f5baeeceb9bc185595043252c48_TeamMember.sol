// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./SafeMath.sol";

contract TeamMember is Ownable
{
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;
    
    event NewMember(uint256 memberID);
    event ReferalBonus(uint256 memberID);
    event TeamGrowthBonus(uint256 memberID);
    event GenerationalBonus(uint256 memberID, uint256 level);
    event Log(string _s);
    
    uint256 public purchaseTime = 35 days;

    /**
    * @dev Allows the Purchase Time to be changed from 35 days for future membership purchases
    */
    function setPurchaseTime(uint256 _time) external onlyOwner {
        purchaseTime = _time;
    }

    uint256 public purchasePrice = 0.05 ether;

    /**
    * @dev Allows the Purchase Price to be changed from 0.05 ether to keep it priced similar to starting USD price for future membership purchases
    */
    function setPurchasePrice(uint256 _price) external onlyOwner {
        purchasePrice = _price;
    }
    
    uint256 public transferPrice = 0.1 ether;

    /**
    * @dev Allows the Transfer Price to be changed from 0.1 ether to keep it priced similar to starting USD price for transfers
    */
    function setTransferPrice(uint256 _price) external onlyOwner {
        transferPrice = _price;
    }

    address private _primary;

    /**
    * @dev Allows the Transfer Price to be changed from 0.1 ether to keep it priced similar to starting USD price for transfers
    */
    function setPrimary(address _newPrime) external onlyOwner {
        _primary = _newPrime;
    }

    uint256 public memberCount = 0;
    
    struct Member
    {
        address account;            // Address of the Member
        address sponsor;            // Address of their sponsor
        uint256 salesMade;          // Number of Direct Members this Member sponsored
        bool topLevel;              // Flag to say this is a special account that is always active and meets all criteria (ID 1)
        uint256 membershipEnds;     // For all other accounts...when the subscription ends
    }
    
    mapping (uint256 => Member) public members;
    
    mapping (address => uint256) internal ownerToMember;      // Get the ID for a given address
    mapping (uint256 => address) internal memberToOwner;      // Get the address for a given ID
    mapping (uint256 => address) internal memberToSponsor;    // Get the sponsor address for a given member ID

    /**
    * @dev The Member constructor adds the owner as the base user account in the system (ID 1)
    */
    constructor()
    {
        _primary = msg.sender;
        _addMember(_primary, true, address(0x0));
    }

    /**
    * @dev Default function adds time to the current person
    */
    receive() external payable {
        renewMembership();
    }
    
    /**
    * @dev Default function adds time to the current person
    */
    fallback() external payable {
        renewMembership();
    }

    /**
    * @dev The addition of a new member to the system (whether special or not) keeping all of the mappings up to date
    */
    function _addMember(address _member, bool _special, address _sponsor) internal {
        memberCount = memberCount.add(1);
        members[memberCount] = Member(_member, _sponsor, 0, _special, purchaseTime.add(block.timestamp));
        emit NewMember(memberCount);

        ownerToMember[_member] = memberCount;
        memberToOwner[memberCount] = _member;
        memberToSponsor[memberCount] = _sponsor;
    }
    
    /**
    * @dev The addition of a special (always active) user in the system
    */
    function addSpecialMember(address _member, address _sponsor) external onlyOwner {
        require(getID(_member) == 0, "Account Already Exists");
        require(getID(_sponsor) != 0, "Sponsor Doesn't Exist");
        _addMember(_member, true, _sponsor);
    }

    /**
    * @dev The addition of a new member for the specified time and price under the specified sponsor
    */
    function newMemberJoin(address _sponsor) external payable {
        require(getID(msg.sender) == 0, "Account Already Exists");
        require(getID(_sponsor) != 0, "Sponsor Doesn't Exist");
        require(msg.value == purchasePrice, "Incorrect Amount Sent");
        
        _addMember(msg.sender, false, _sponsor);
        
        Member storage m = members[ownerToMember[_sponsor]];
        m.salesMade = m.salesMade.add(1);
        
        _distributeFunds(getID(msg.sender), msg.value);
    }

    /**
    * @dev Add the specified time and distribute the price for the renewal
    */
    function renewMembership() public payable {
        require(getID(msg.sender) != 0, "Member Not Found");
        require(msg.value == purchasePrice, "Incorrect Amount Sent");

        Member storage m = members[getID(msg.sender)];
        if(m.membershipEnds > block.timestamp) {
            m.membershipEnds = m.membershipEnds.add(purchaseTime);
        }
        else {
            m.membershipEnds = purchaseTime.add(block.timestamp);
        }
        
        _distributeFunds(getID(msg.sender), msg.value);
    }
    
    /**
    * @dev Used to distribute funds to the members based upon the comp plan
    *       25% to the sponsor of the member ID
    *       25% to the Team Growth Bonus Qualified upline
    *       50% to 10 Generational Bonus Qualified upline
    */
    function _distributeFunds(uint256 _currentID, uint256 _amount) internal
    {
        address sponsor = memberToSponsor[_currentID];
        bool success;
        if(sponsor == address(0x0))
        {
            (success, ) = _primary.call{value: _amount}("");
            require(success, "Transfer failed.");
            return;
        }
        
        uint256 pp4 = _amount.div(4);       // Used for the 2 25% payments
        uint256 pp20 = _amount.div(20);     // Used for the 10 gen bonuses
        
        uint256 spID = getID(sponsor);
        
        // Pay the sponsor no matter what..
        (success, ) = sponsor.call{value: pp4}("");
        require(success, "Transfer failed to pay sponsor.");
        emit ReferalBonus(spID);
        
        // Pay the Team Growth Bonus...
        if(isTeamGrowthQualified(sponsor, getAddress(_currentID)))
        {
            (success, ) = sponsor.call{value: pp4}("");
            require(success, "Transfer failed to pay sponsor.");
            emit TeamGrowthBonus(spID);
        }
        else
        {
            address prior = sponsor;
            address tg = memberToSponsor[spID];     // Start with first upline of the sponsor
            while((tg != address(0x0)) && (!isTeamGrowthQualified(tg, prior)))
            {
                prior = tg;
                tg = memberToSponsor[getID(prior)];
            }
            if(tg == address(0x0))
            {
                (success, ) = _primary.call{value: pp4}("");
                require(success, "Transfer failed.");
            }
            else
            {
                (success, ) = tg.call{value: pp4}("");
                require(success, "Transfer failed.");
                emit TeamGrowthBonus(getID(tg));
            }
        }

        // Pay the Generational Bonuses...
        address gen = sponsor;
        uint256 level = 1;
        while(level < 3)        // Find Active Affiliates for level 1 and 2
        {
            while((gen != address(0x0)) && (!isActiveByAddress(gen)))
            {
                gen = memberToSponsor[getID(gen)];
            }
            if(gen == address(0x0))
            {
                (success, ) = _primary.call{value: pp20}("");
                require(success, "Transfer failed.");
            }
            else
            {
                (success, ) = gen.call{value: pp20}("");
                require(success, "Transfer failed.");
                emit GenerationalBonus(getID(gen), level);
            }
            level = level.add(1);
        }
        if(gen != address(0x0)) gen = memberToSponsor[getID(gen)];
        while(level < 6)        // Find Active Smart Affiliates for level 3, 4 and 5
        {
            while((gen != address(0x0)) && (!isSmartAffiliate(gen)))
            {
                gen = memberToSponsor[getID(gen)];
            }
            if(gen == address(0x0))
            {
                (success, ) = _primary.call{value: pp20}("");
                require(success, "Transfer failed.");
            }
            else
            {
                (success, ) = gen.call{value: pp20}("");
                require(success, "Transfer failed.");
                emit GenerationalBonus(getID(gen), level);
            }
            level = level.add(1);
        }
        if(gen != address(0x0)) gen = memberToSponsor[getID(gen)];
        while(level <= 10)        // Find Active Super Affiliates for level 6-10
        {
            while((gen != address(0x0)) && (!isSuperAffiliate(gen)))
            {
                gen = memberToSponsor[getID(gen)];
            }
            if(gen == address(0x0))
            {
                (success, ) = _primary.call{value: pp20}("");
                require(success, "Transfer failed.");
            }
            else
            {
                (success, ) = gen.call{value: pp20}("");
                require(success, "Transfer failed.");
                emit GenerationalBonus(getID(gen), level);
            }
            level = level.add(1);
        }
    }
    
    /**
    * @dev Quick way to get the ID from an address in the system
    */
    function getID(address _member) view public returns(uint256) {
        return ownerToMember[_member];
    }

    /**
    * @dev Quick way to get the address from an ID in the system
    */
    function getAddress(uint256 _memberID) view public returns(address) {
        return memberToOwner[_memberID];
    }

    /**
    * @dev Quick way to get a member structure from a member ID
    */
    function getMemberByID(uint256 _memberID) view public returns(Member memory) {
        assert(_memberID != 0);
        assert(_memberID <= memberCount);
        return members[_memberID];
    }

    /**
    * @dev Quick way to get a member structure from a member ID
    */
    function getMemberByAddress(address _member) view public returns(Member memory) {
        return getMemberByID(getID(_member));
    }

    /**
    * @dev Determines if the user is special (always active) or has remaining days left of their membership
    */
    function isActiveByAddress(address _member) view internal returns(bool) {
        return members[ownerToMember[_member]].topLevel || members[ownerToMember[_member]].membershipEnds > block.timestamp;
    }

    /**
    * @dev Determines if the user is special (always active) or has remaining days left of their membership
    */
    function isActiveByID(uint256 _memberID) view internal returns(bool) {
        return members[_memberID].topLevel || members[_memberID].membershipEnds > block.timestamp;
    }

    /**
    * @dev Traverse the list to get the IDs of all members sponsored by this address
    */
    function getMembersByOwner(address _owner) internal view returns(uint256[] memory) {
        uint256[] memory result;
        uint256 numSales = getMemberByAddress(_owner).salesMade;
        if(numSales < 1) return result;
        result = new uint256[](numSales);
        uint counter = 0;
        for (uint i = 1; i <= memberCount; i++) {
            if (memberToSponsor[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    
    /**
    * @dev Get the ID of the first member they ever sold a membership to (used to determine eligibility for Team bonuses)
    */
    function getFirstMemberID(address _owner) internal view returns(uint256) {
        uint256 numSales = getMemberByAddress(_owner).salesMade;
        if(numSales < 1) return 0;
        for (uint i = 1; i <= memberCount; i++) {
            if (memberToSponsor[i] == _owner) return i;
        }
        return 0;
    }

    /**
    * @dev Determines whether the member has sold any memberships yet at all
    */
    function hasMembers(address _owner) view public returns(bool) {
        return membershipsSold(_owner) > 0;
    }

    /**
    * @dev Determines how many members have ever purchased from a user (need to know if they have at least 2 or not in some cases)
    *       same as number of directs to this user
    */
    function membershipsSold(address _owner) view public returns(uint256) {
        return getMemberByAddress(_owner).salesMade;
    }

    /**
    * @dev Make sure they have two sales and the _from address member is not in the 1st line of their team
    */
    function isTeamGrowthQualified(address _owner, address _from) view public returns(bool) {
        if(getMemberByAddress(_owner).topLevel) return true;
        return ((membershipsSold(_owner) > 1) && (getFirstMemberID(_owner) != getID(_from)));
    }

    /**
    * @dev Determines whether the member still has at least 3 Active Affiliates
    */
    function isSmartAffiliate(address _owner) view public returns(bool) {
        if(getMemberByAddress(_owner).topLevel) return true;    // topLevel is always active and qualified
        if(!isActiveByAddress(_owner)) return false;                 // Must be active themselves to be qualified for this

        uint256[] memory mems = getMembersByOwner(_owner); // All member IDs of their directs
        uint256 numSales = mems.length;
        uint256 numActive = 0;

        for (uint i = 0; i < numSales; i++) {
            // Just need to find those they sponsored that are active right now
            if (isActiveByID(mems[i])) {
                numActive = numActive.add(1);
                if(numActive > 2) return true; // As soon as we find a third active Affiliate we are done
            }
        }
        return false;
    }

    /**
    * @dev Determines whether the member still has at least 3 Active Smart Affiliates
    */
    function isSuperAffiliate(address _owner) view public returns(bool) {
        if(getMemberByAddress(_owner).topLevel) return true; // topLevel is always active and qualified
        if(!isActiveByAddress(_owner)) return false; // Must be active first to be qualified

        uint256[] memory mems = getMembersByOwner(_owner);
        uint256 numSales = mems.length;
        uint256 numActive = 0;

        for (uint i = 0; i < numSales; i++) {
            // Smart Affiliate means they are active with three active so it does the second level checks for us
            if (isSmartAffiliate(memberToOwner[mems[i]])) {
                numActive = numActive.add(1);
                if(numActive > 2) return true; // As soon as we find a third Smart Affiliate we are done
            }
        }
        return false;
    }

    /**
    * @dev Allows a User to change the address associated with their membership to a new address (theirs or someone they are selling it to)
    */
    function transferMemberPosition(address _to) external payable
    {
        require(msg.value == transferPrice, "Incorrect Amount Sent");
        require(getID(msg.sender) != 0, "Member Account Not Found");
        require(getID(_to) == 0, "To Account Already Exists");

        (bool success, ) = _primary.call{value: transferPrice}("");
        require(success, "Transfer failed.");

        uint256 memberID = ownerToMember[msg.sender];
        uint256[] memory mems = getMembersByOwner(msg.sender);
        uint256 numSales = mems.length;
        Member storage m = members[memberID];
        m.account = _to;
        delete ownerToMember[msg.sender];
        ownerToMember[_to] = memberID;
        memberToOwner[memberID] = _to;
        for(uint256 i = 0; i < numSales; i++){
            members[mems[i]].sponsor = _to;
            memberToSponsor[mems[i]] = _to;
        }
    }
}