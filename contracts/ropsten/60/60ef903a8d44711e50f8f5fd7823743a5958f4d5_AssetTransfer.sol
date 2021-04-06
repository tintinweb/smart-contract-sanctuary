/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity >=0.4.25 <0.6.0;

contract AssetTransfer
{
    enum StateType { Active, OfferPlaced, PendingInspection, Inspected, Appraised, NotionalAcceptance, BuyerAccepted, SellerAccepted, Accepted, Terminated }
    address public InstanceOwner;
    string public Description;
    uint public AskingPrice;
    StateType public State;

    address public InstanceBuyer;
    uint public OfferPrice;
    address public InstanceInspector;
    address public InstanceAppraiser;

    constructor(string memory description, uint256 price) public
    {
        InstanceOwner = msg.sender;
        AskingPrice = price;
        Description = description;
        State = StateType.Active;
    }

    function Terminate() public
    {
        if (InstanceOwner != msg.sender)
        {
        //    revert();
        }

        State = StateType.Terminated;
    }

    function Modify(string memory description, uint256 price) public
    {
        if (State != StateType.Active)
        {
        //    revert();
        }
        if (InstanceOwner != msg.sender)
        {
        //    revert();
        }

        Description = description;
        AskingPrice = price;
    }

    function MakeOffer(address inspector, address appraiser, uint256 offerPrice) public
    {
        if (inspector == 0x0000000000000000000000000000000000000000 || appraiser == 0x0000000000000000000000000000000000000000 || offerPrice == 0)
        {
        //    revert();
        }
        if (State != StateType.Active)
        {
        //    revert();
        }
        // Cannot enforce "AllowedRoles":["Buyer"] because Role information is unavailable
        if (InstanceOwner == msg.sender) // not expressible in the current specification language
        {
        //    revert();
        }

        InstanceBuyer = msg.sender;
        InstanceInspector = inspector;
        InstanceAppraiser = appraiser;
        OfferPrice = offerPrice;
        State = StateType.OfferPlaced;
    }

    function AcceptOffer() public
    {
        if (State != StateType.OfferPlaced)
        {
         //   revert();
        }
        if (InstanceOwner != msg.sender)
        {
         //   revert();
        }

        State = StateType.PendingInspection;
    }

    function Reject() public
    {
        if (State != StateType.OfferPlaced && State != StateType.PendingInspection && State != StateType.Inspected && State != StateType.Appraised && State != StateType.NotionalAcceptance && State != StateType.BuyerAccepted)
        {
        //    revert();
        }
        if (InstanceOwner != msg.sender)
        {
        //    revert();
        }

        InstanceBuyer = 0x0000000000000000000000000000000000000000;
        State = StateType.Active;
    }

    function Accept() public
    {
        if (msg.sender != InstanceBuyer && msg.sender != InstanceOwner)
        {
        //    revert();
        }

        if (msg.sender == InstanceOwner &&
            State != StateType.NotionalAcceptance &&
            State != StateType.BuyerAccepted)
        {
        //    revert();
        }

        if (msg.sender == InstanceBuyer &&
            State != StateType.NotionalAcceptance &&
            State != StateType.SellerAccepted)
        {
        //    revert();
        }

        if (msg.sender == InstanceBuyer)
        {
            if (State == StateType.NotionalAcceptance)
            {
                State = StateType.BuyerAccepted;
            }
            else if (State == StateType.SellerAccepted)
            {
                State = StateType.Accepted;
            }
        }
        else
        {
            if (State == StateType.NotionalAcceptance)
            {
                State = StateType.SellerAccepted;
            }
            else if (State == StateType.BuyerAccepted)
            {
                State = StateType.Accepted;
            }
        }
    }

    function ModifyOffer(uint256 offerPrice) public
    {
        if (State != StateType.OfferPlaced)
        {
        //    revert();
        }
        if (InstanceBuyer != msg.sender || offerPrice == 0)
        {
         //   revert();
        }

        OfferPrice = offerPrice;
    }

    function RescindOffer() public
    {
        if (State != StateType.OfferPlaced && State != StateType.PendingInspection && State != StateType.Inspected && State != StateType.Appraised && State != StateType.NotionalAcceptance && State != StateType.SellerAccepted)
        {
        //    revert();
        }
        if (InstanceBuyer != msg.sender)
        {
        //    revert();
        }

        InstanceBuyer = 0x0000000000000000000000000000000000000000;
        OfferPrice = 0;
        State = StateType.Active;
    }

    function MarkAppraised() public
    {
        if (InstanceAppraiser != msg.sender)
        {
        //    revert();
        }

        if (State == StateType.PendingInspection)
        {
            State = StateType.Appraised;
        }
        else if (State == StateType.Inspected)
        {
            State = StateType.NotionalAcceptance;
        }
        else
        {
        //    revert();
        }
    }

    function MarkInspected() public
    {
        if (InstanceInspector != msg.sender)
        {
        //    revert();
        }

        if (State == StateType.PendingInspection)
        {
            State = StateType.Inspected;
        }
        else if (State == StateType.Appraised)
        {
            State = StateType.NotionalAcceptance;
        }
        else
        {
        //    revert();
        }
    }
}