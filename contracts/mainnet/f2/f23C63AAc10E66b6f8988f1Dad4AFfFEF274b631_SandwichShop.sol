pragma solidity ^0.4.11;

contract SandwichShop
{
    address owner;

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    struct Sandwich
    {
        uint sandwichID;
        string sandwichName;
        string sandwichDesc;
        string calories;
        uint price;
        uint quantity;
    }

    struct OrderedSandwich
    {
        uint sandwichIdNumber;
        string notes;
        uint price;
    }
    
    event NewSandwichTicket( string name, address customer, string sandName, string sandChanges );

    Sandwich[5] shopSandwich;
    mapping( address => OrderedSandwich[] ) public cart;
    mapping( address => uint ) public subtotal;

    function SandwichShop() public
    {
        owner = msg.sender;

        shopSandwich[0].sandwichID = 0;
        shopSandwich[0].sandwichName = &quot;00:  Ham & Swiss&quot;;
        shopSandwich[0].sandwichDesc = &quot;Ham Swiss Mustard Rye&quot;;
        shopSandwich[0].calories = &quot;450 calories&quot;;
        shopSandwich[0].price = 40 finney;
        shopSandwich[0].quantity = 200;

        shopSandwich[1].sandwichID = 1;
        shopSandwich[1].sandwichName = &quot;01:  Turkey & Pepperjack&quot;;
        shopSandwich[1].sandwichDesc = &quot;Turkey Pepperjack Mayo White Bread&quot;;
        shopSandwich[1].calories = &quot;500 calories&quot;;
        shopSandwich[1].price = 45 finney;
        shopSandwich[1].quantity = 200;

        shopSandwich[2].sandwichID = 2;
        shopSandwich[2].sandwichName = &quot;02:  Roast Beef & American&quot;;
        shopSandwich[2].sandwichDesc = &quot;Roast Beef Havarti Horseradish White Bread&quot;;
        shopSandwich[2].calories = &quot;600 calories&quot;;
        shopSandwich[2].price = 50 finney;
        shopSandwich[2].quantity = 200;

        shopSandwich[3].sandwichID = 3;
        shopSandwich[3].sandwichName = &quot;03:  Reuben&quot;;
        shopSandwich[3].sandwichDesc = &quot;Corned Beef Sauerkraut Swiss Rye&quot;;
        shopSandwich[3].calories = &quot;550 calories&quot;;
        shopSandwich[3].price = 50 finney;
        shopSandwich[3].quantity = 200;

        shopSandwich[4].sandwichID = 4;
        shopSandwich[4].sandwichName = &quot;04:  Italian&quot;;
        shopSandwich[4].sandwichDesc = &quot;Salami Peppers Provolone Oil Vinegar White&quot;;
        shopSandwich[4].calories = &quot;500 calories&quot;;
        shopSandwich[4].price = 40 finney;
        shopSandwich[4].quantity = 200;
    }

    function getMenu() constant returns (string, string, string, string, string)
    {
        return (shopSandwich[0].sandwichName, shopSandwich[1].sandwichName,
                shopSandwich[2].sandwichName, shopSandwich[3].sandwichName,
                shopSandwich[4].sandwichName );
    }

    function getSandwichInfo(uint _sandwichId) constant returns (string, string, string, uint, uint)
    {
        if( _sandwichId > 4 )
        {
            return ( &quot;wrong ID&quot;, &quot;wrong ID&quot;, &quot;zero&quot;, 0, 0);
        }
        else
        {
            return (shopSandwich[_sandwichId].sandwichName, shopSandwich[_sandwichId].sandwichDesc,
                    shopSandwich[_sandwichId].calories, shopSandwich[_sandwichId].price, shopSandwich[_sandwichId].quantity);

        }
    }

    function addToCart(uint _sandwichID, string _notes) returns (uint)
    {
        if( shopSandwich[_sandwichID].quantity > 0 )
        {
            OrderedSandwich memory newOrder;
            newOrder.sandwichIdNumber = _sandwichID;
            newOrder.notes = _notes;
            newOrder.price = shopSandwich[_sandwichID].price;
            subtotal[msg.sender] += newOrder.price;

            return cart[msg.sender].push(newOrder);
        }
        else
        {
            return cart[msg.sender].length;
        }
    }


    function getCartLength(address _curious) constant returns (uint)
    {
        return cart[_curious].length;
    }

    function getCartItemInfo(address _curious, uint _slot) constant returns (string)
    {
        return cart[_curious][_slot].notes;
    }

    function emptyCart() public
    {
        delete cart[msg.sender];
        subtotal[msg.sender] = 0;
    }

    function getCartSubtotal(address _curious) constant returns (uint)
    {
        return subtotal[_curious];
    }

    function checkoutCart(string _firstname) payable returns (uint)
    {
        if( msg.value < subtotal[msg.sender] ){ revert(); }

        for( uint x = 0; x < cart[msg.sender].length; x++ )
        {
            if( shopSandwich[ cart[msg.sender][x].sandwichIdNumber ].quantity > 0 )
            {
                NewSandwichTicket( _firstname, msg.sender, 
                                   shopSandwich[ cart[msg.sender][x].sandwichIdNumber ].sandwichName,
                                   cart[msg.sender][x].notes );
                decrementQuantity( cart[msg.sender][x].sandwichIdNumber );
            }
            else
            {
                revert();
            }
        }
        subtotal[msg.sender] = 0;
        delete cart[msg.sender];
    }

    function transferFundsAdminOnly(address addr, uint amount) onlyOwner
    {
        if( amount <= this.balance )
        {
            addr.transfer(amount);
        }
    }

    function decrementQuantity(uint _sandnum) private
    {
        shopSandwich[_sandnum].quantity--;
    }

    function setQuantityAdminOnly(uint _sandnum, uint _quantity) onlyOwner
    {
        shopSandwich[_sandnum].quantity = _quantity;
    }

    function killAdminOnly() onlyOwner
    {
        selfdestruct(owner);
    }

}