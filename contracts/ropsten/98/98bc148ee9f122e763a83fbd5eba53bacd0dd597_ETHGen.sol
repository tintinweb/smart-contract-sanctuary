// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./SafeMath.sol";

contract ETHGen is Ownable
{
    using SafeMath for uint256;

    // Allow front end systems to know when new members are added to the tree
    event NewMember(
        uint256 indexed memberID
    );
    
    // Allow front end systems to know when a referal is earned by a member (and from who)
    event ReferalBonus(
        uint256 indexed memberID,   // member who earned the commission
        uint256 indexed saleID      // member who paid for their subscription
    );
    
    // Allow front end systems to know when a team bonus is earned by a member
    event TeamGrowthBonus(
        uint256 indexed memberID,   // member who earned the commission
        uint256 indexed saleID      // member who paid for their subscription
    );
    
    // Allow front end systems to know when a generational bonus is earned by a member
    event GenerationalBonus(
        uint256 indexed memberID,   // member who earned the commission
        uint256 indexed saleID,     // member who paid for their subscription
        uint256 indexed level       // Which Generation Level was earned (1 is first sponsor - 10 the top Super paid)
    );

    // The amount of time added to the subscription for each payment of purchasePrice below
    uint256 public purchaseTime = 35 days;

    /**
    * @dev Allows the Purchase Time to be changed from 35 days for future membership purchases
    */
    function setPurchaseTime(uint256 _time) external onlyOwner
    {
        purchaseTime = _time;
    }

    // The price to purchase time on the subscription based upon the number of days in PurchaseTime above
    uint256 public purchasePrice = 0.05 ether;

    /**
    * @dev Allows the Purchase Price to be changed from 0.05 ether to keep it priced similar to starting USD price for future membership purchases
    */
    function setPurchasePrice(uint256 _price) external onlyOwner
    {
        purchasePrice = _price;
    }

    // Price to transfer from one wallet address to another (in the case of a compromised account or account sale)    
    uint256 public transferPrice = 0.1 ether;

    /**
    * @dev Allows the Transfer Price to be changed from 0.1 ether to keep it priced similar to starting USD price for transfers
    */
    function setTransferPrice(uint256 _price) external onlyOwner
    {
        transferPrice = _price;
    }

    // Over run account...if bonuses are to be paid and no accounts are found that match the criteria
    address private _primary;

    /**
    * @dev Allows the account that over runs will roll up into to be changed
    */
    function setPrimary(address _newPrime) external onlyOwner
    {
        _primary = _newPrime;
    }

    // Used to iterate through the member list and can be used to display the total number of participants
    uint256 public memberCount = 0;
    
    struct Member
    {
        address account;            // Address of the Member
        address sponsor;            // Address of their sponsor
        uint256 salesMade;          // Number of Direct Members this Member sponsored
        bool    masterLevel;        // Flag to say this is a special account that is always active and meets all criteria (ID 1, and others)
        uint256 membershipEnds;     // For all other accounts...when the subscription ends
    }
    mapping (uint256 => Member) public members;

    // Used for easier lookups within the system
    mapping (address => uint256) internal ownerToMember;      // Get the ID for a given address
    mapping (uint256 => address) internal memberToOwner;      // Get the address for a given ID
    mapping (uint256 => address) internal memberToSponsor;    // Get the sponsor address for a given member ID

    /**
    * @dev The Member constructor adds the owner as the base user account in the system (ID 1)
    */
    constructor()
    {
        _primary = msg.sender;
        _addMember(_primary, true, address(0x0), 1);
    }

    /**
    * @dev Default function adds time to the current person
    */
    receive() external payable
    {
        renewMembership(1);
    }
    
    /**
    * @dev Default function adds time to the current person
    */
    fallback() external payable
    {
        renewMembership(1);
    }

    /**
    * @dev The addition of a new member to the system (whether special or not) keeping all of the mappings up to date
    */
    function _addMember(address _member, bool _special, address _sponsor, uint256 _numPeriods) internal
    {
        memberCount = memberCount.add(1);
        members[memberCount] = Member(_member, _sponsor, 0, _special, (_numPeriods.mul(purchaseTime)).add(block.timestamp));
        emit NewMember(memberCount);

        ownerToMember[_member] = memberCount;
        memberToOwner[memberCount] = _member;
        memberToSponsor[memberCount] = _sponsor;
    }
    
    /**
    * @dev The addition of a special (always active) user in the system
    */
    function addSpecialMember(address _member, address _sponsor) external onlyOwner
    {
        require(getID(_member) == 0, "Account Already Exists");
        require(getID(_sponsor) != 0, "Sponsor Doesn't Exist");
        _addMember(_member, true, _sponsor, 1);
    }

    /**
    * @dev The addition of a new member for the specified time and price under the specified sponsor
    */
    function newMemberJoin(address _sponsor, uint256 _numPeriods) external payable
    {
        require(getID(msg.sender) == 0, "Account Already Exists");
        require(getID(_sponsor) != 0, "Sponsor Doesn't Exist");
        require(msg.value == _numPeriods.mul(purchasePrice), "Incorrect Amount Sent");
        
        _addMember(msg.sender, false, _sponsor, _numPeriods);
        
        Member storage m = members[ownerToMember[_sponsor]];
        m.salesMade = m.salesMade.add(1);
        
        _distributeFunds(_sponsor, getID(msg.sender), msg.value);
    }

    /**
    * @dev Add the specified time and distribute the price for the renewal
    */
    function renewMembership(uint256 _numPeriods) public payable
    {
        require(_numPeriods > 0, "Must Include at Least 1 Period");
        require(getID(msg.sender) != 0, "Member Not Found");
        require(msg.value == (_numPeriods.mul(purchasePrice)),  "Incorrect Amount Sent");

        Member storage m = members[getID(msg.sender)];
        // Check for expired membership
        if(m.membershipEnds > block.timestamp)
        {
            // They were not expired...so we extend it out further by the days in purchaseTime * number of periods
            m.membershipEnds = m.membershipEnds.add(_numPeriods.mul(purchaseTime));
        }
        else
        {
            // They were expired...so we start them with a fresh number of days in purchaseTime * number of periods
            m.membershipEnds = (purchaseTime.mul(_numPeriods)).add(block.timestamp);
        }
        
        _distributeFunds(memberToSponsor[getID(msg.sender)], getID(msg.sender), msg.value);
    }
    
    /**
    * @dev Used to distribute funds to the members based upon the comp plan
    *       25% to the sponsor of the member ID
    *       25% to the Team Growth Bonus Qualified upline
    *        5% to each of 10 Generational Bonus Qualified upline
    *      ----
    *      100% paid out = none collected by the smart contract (complete member-to-member payout)
    * 
    *           Note: _currentID can be 0 if it was a customer (not a distributor) sale being paid out
    */
    function _distributeFunds(address sponsor, uint256 _currentID, uint256 _amount) internal
    {
        bool success;
        if(sponsor == address(0x0))
        {
            (success, ) = _primary.call{value: _amount}("");
            require(success, "Transfer failed.");
            return;
        }
        
        uint256 spID = getID(sponsor);
        require(spID != 0, "Sponsor Not Found In System");
        
        uint256 pp4 = _amount.div(4);       // Used for the 2 25% payments
        uint256 pp20 = _amount.div(20);     // Used for the 10 5% gen bonuses

        // Pay the sponsor no matter what..
        (success, ) = sponsor.call{value: pp4}("");
        require(success, "Transfer failed to pay sponsor.");
        emit ReferalBonus(spID, _currentID);
        
        // Pay the Team Growth Bonus...
        // Note the direct sponsor never gets these for their first two membership positions (even on renewals)
        // -- and they can't be collected from the first line of sponsorship either --
        if(isTeamGrowthQualified(sponsor, _currentID) && (getSecondMemberID(sponsor) != _currentID))
        {
            (success, ) = sponsor.call{value: pp4}("");
            require(success, "Transfer failed to pay sponsor.");
            emit TeamGrowthBonus(spID, _currentID);
        }
        else
        {
            address prior = sponsor;
            address tg = memberToSponsor[spID];     // Start with first upline of the sponsor
            while((tg != address(0x0)) && (!isTeamGrowthQualified(tg, getID(prior))))
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
                emit TeamGrowthBonus(getID(tg), _currentID);
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
                emit GenerationalBonus(getID(gen), _currentID, level);
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
                emit GenerationalBonus(getID(gen), _currentID, level);
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
                emit GenerationalBonus(getID(gen), _currentID, level);
            }
            level = level.add(1);
        }
    }
    
    /**
    * @dev Quick way to get the ID from an address in the system
    */
    function getID(address _member) view public returns(uint256)
    {
        return ownerToMember[_member];
    }

    /**
    * @dev Quick way to get the address from an ID in the system
    */
    function getAddress(uint256 _memberID) view public returns(address)
    {
        return memberToOwner[_memberID];
    }

    /**
    * @dev Quick way to get a member structure from a member ID
    */
    function getMemberByID(uint256 _memberID) view public returns(Member memory)
    {
        require(_memberID != 0, "Not a Valid ID");
        require(_memberID <= memberCount, "Not a Valid ID");
        return members[_memberID];
    }

    /**
    * @dev Quick way to get a member structure from a member address
    */
    function getMemberByAddress(address _member) view public returns(Member memory)
    {
        require(_member != address(0x0), "Not a Valid Address");
        return members[getID(_member)];
    }

    /**
    * @dev Determines if the user is special (always active) or has remaining days left of their membership
    */
    function isActiveByAddress(address _member) view public returns(bool)
    {
        require(_member != address(0x0), "Not a Valid Address");
        uint256 ID = ownerToMember[_member];
        require(ID != 0, "Not a Valid ID");
        require(ID <= memberCount, "Not a Valid ID");
        return members[ID].masterLevel || members[ID].membershipEnds > block.timestamp;
    }

    /**
    * @dev Determines if the user is special (always active) or has remaining days left of their membership
    */
    function isActiveByID(uint256 _memberID) view public returns(bool)
    {
        require(_memberID != 0, "Not a Valid ID");
        require(_memberID <= memberCount, "Not a Valid ID");
        return members[_memberID].masterLevel || members[_memberID].membershipEnds > block.timestamp;
    }

    /**
    * @dev Traverse the list to get the IDs of all members sponsored by this address
    */
    function getMembersByOwner(address _owner) internal view returns(uint256[] memory)
    {
        uint256[] memory result;
        
        uint256 numSales = getMemberByAddress(_owner).salesMade;
        if(numSales < 1) return result;
        
        result = new uint256[](numSales);
        uint counter = 0;
        for (uint i = 1; i <= memberCount; i++)
        {
            if (memberToSponsor[i] == _owner)
            {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    
    /**
    * @dev Get the ID of the first member they ever sold a membership to (used to determine eligibility for Team bonuses)
    */
    function getFirstMemberID(address _owner) internal view returns(uint256)
    {
        uint256 numSales = getMemberByAddress(_owner).salesMade;
        if(numSales < 1) return 0;
        
        for (uint i = 1; i <= memberCount; i++)
        {
            if (memberToSponsor[i] == _owner) return i;
        }
        return 0;
    }

    /**
    * @dev Get the ID of the second member they ever sold a membership to (used to determine eligibility for Team bonuses)
    */
    function getSecondMemberID(address _owner) internal view returns(uint256)
    {
        uint256 numSales = getMemberByAddress(_owner).salesMade;
        if(numSales < 1) return 0;
        bool firstFound = false;
        
        for (uint i = 1; i <= memberCount; i++)
        {
            if (memberToSponsor[i] == _owner)
            {
                if(!firstFound) firstFound = true;
                else return i;
            }
        }
        return 0;
    }

    /**
    * @dev Determines whether the member has sold any memberships yet at all
    */
    function hasMembers(address _owner) view public returns(bool)
    {
        return membershipsSold(_owner) > 0;
    }

    /**
    * @dev Determines how many members have ever purchased from a user (need to know if they have at least 2 or not in some cases)
    *       same as number of directs to this user
    */
    function membershipsSold(address _owner) view public returns(uint256)
    {
        if(getID(_owner) == 0) return 0;
        return getMemberByAddress(_owner).salesMade;
    }

    /**
    * @dev Make sure they have two sales and the _from ID member is not in the 1st line of their team
    */
    function isTeamGrowthQualified(address _owner, uint256 _from) view public returns(bool)
    {
        if(getMemberByAddress(_owner).masterLevel) return true;     // masterLevel is always active and qualified
        if(!isActiveByAddress(_owner)) return false;                // Must be active themselves to be qualified for this
        // Note: For sales to a direct, personally enrolled, a check is still needed that it is not the second personally enrolled
        return ((membershipsSold(_owner) > 1) && (getFirstMemberID(_owner) != _from));
    }

    /**
    * @dev Determines whether the member still has at least 3 Active Affiliates
    */
    function isSmartAffiliate(address _owner) view public returns(bool)
    {
        if(getMemberByAddress(_owner).masterLevel) return true;     // masterLevel is always active and qualified
        if(!isActiveByAddress(_owner)) return false;                // Must be active themselves to be qualified for this

        uint256[] memory mems = getMembersByOwner(_owner);          // Get All member IDs of their directs

        uint256 numSales = mems.length;
        uint256 numActive = 0;

        for (uint i = 0; i < numSales; i++)
        {
            // Just need to find those they sponsored that are active right now
            if (isActiveByID(mems[i]))
            {
                if(numActive >= 2) return true; // As soon as we find a third active Affiliate we are done...no need to add to the temp variable
                numActive = numActive.add(1);
            }
        }
        return false;
    }

    /**
    * @dev Determines whether the member still has at least 3 Active Smart Affiliates
    */
    function isSuperAffiliate(address _owner) view public returns(bool)
    {
        if(getMemberByAddress(_owner).masterLevel) return true;     // masterLevel is always active and qualified
        if(!isActiveByAddress(_owner)) return false;                // Must be active first to be qualified

        uint256[] memory mems = getMembersByOwner(_owner);
        
        uint256 numSales = mems.length;
        uint256 numActive = 0;

        for (uint i = 0; i < numSales; i++)
        {
            // Smart Affiliate means they are active with three active so it does the second level checks for us
            if (isSmartAffiliate(memberToOwner[mems[i]]))
            {
                if(numActive >= 2) return true; // As soon as we find a third Smart Affiliate we are done...no need to add to the temp variable here
                numActive = numActive.add(1);
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
        for(uint256 i = 0; i < numSales; i++)
        {
            members[mems[i]].sponsor = _to;
            memberToSponsor[mems[i]] = _to;
        }
    }
    
    /**
    * @dev Allows a Vendor to send commissions to the network
    * 
    *   _vendorAmountInGWEI + _distAmountInGWEI must match the amount sent by the purchaser
    * 
    *   5% of the vendor amount goes to ETH Gen as sales commissions unless the entire amount is sent to commission tree
    * 
    *   If the sender is in the system, it determines the sponsor and ignores the _sponsor passed
    *   Otherwise, if the sender is not in the system, the sender is assumed to be a customer and a sponsor should be specified who is responsible for the sale
    *   But, if there is no _sponsor passed, then the amount is considered a house sale and distribution amount starts with the vendor as the sponsor
    */
    function processProductPurchase(address _vendor, address _sponsor, uint256 _vendorAmountInGWEI, uint256 _distAmountInGWEI) external payable
    {
        require(msg.value == (_vendorAmountInGWEI + _distAmountInGWEI), "Incorrect Amount Sent");
        require(address(0x0) != _vendor, "Invalid Vendor Address");

        uint256 eamount = (_vendorAmountInGWEI > 0) ? _vendorAmountInGWEI.div(20) : 0;
        uint256 vamount = _vendorAmountInGWEI.sub(eamount);

        if(eamount > 0)
        {
            (bool success, ) = _primary.call{value: eamount}("");
            require(success, "Transfer failed to ETH Gen.");
        }
        if(vamount > 0)
        {
            (bool success, ) = _vendor.call{value: vamount}("");
            require(success, "Transfer failed to Vendor.");
        }
        if(_distAmountInGWEI > 0)
        {
            uint256 ID = getID(msg.sender);
            if(ID == 0)
            {
                uint256 spID = getID(_sponsor);
                if(spID == 0)
                {
                    uint256 venID = getID(_vendor);
                    require(venID != 0, "Vendor Not Found In System");
                    _distributeFunds(_vendor, ID, _distAmountInGWEI);
                }
                else _distributeFunds(_sponsor, ID, _distAmountInGWEI);
            }
            else _distributeFunds(memberToSponsor[ID], ID, _distAmountInGWEI);
        }

    }
}