pragma solidity ^0.4.11;

contract Pixel {
    /* This creates an array with all balances */
    struct Section {
        address owner;
        uint256 price;
        bool for_sale;
        bool initial_purchase_done;
        uint image_id;
        string md5;
        uint last_update;
        address sell_only_to;
        uint16 index;
        //bytes32[10] image_data;
    }
    string public standard = "IPO 0.9";
    string public constant name = "Initial Pixel Offering";
    string public constant symbol = "IPO";
    uint8 public constant decimals = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public ethBalance;
    address owner;
    uint256 public ipo_price;
    Section[10000] public sections;
    uint256 public pool;
    uint public mapWidth;
    uint public mapHeight;
    uint256 tokenTotalSupply = 10000;

    event Buy(uint section_id);
    event NewListing(uint section_id, uint price);
    event Delisted(uint section_id);
    event NewImage(uint section_id);
    event AreaPrice(uint start_section_index, uint end_section_index, uint area_price);
    event SentValue(uint value);
    event PriceUpdate(uint256 price);
    event WithdrawEvent(string msg);

    function Pixel() {
        pool = tokenTotalSupply; //Number of token / spaces
        ipo_price = 100000000000000000; // 0.1
        mapWidth = 1000;
        mapHeight = 1000;
        owner = msg.sender;
    }

    function totalSupply() constant returns (uint totalSupply)
    {
        totalSupply = tokenTotalSupply;
    }

    /// Updates a pixel section&#39;s index number
    /// Not to be called by anyone but the contract owner
    function updatePixelIndex(
        uint16 _start,
        uint16 _end
    ) {
        if(msg.sender != owner) throw; 
        if(_end < _start) throw;
        while(_start < _end)
        {
            sections[_start].index = _start;
            _start++;
        }
    }

    /// Update the current IPO price
    function updateIPOPrice(
        uint256 _new_price
    ) {
        if(msg.sender != owner) throw;
        ipo_price = _new_price;
        PriceUpdate(ipo_price);
    }

    /* Get the index to access a section object from the provided raw x,y */
    /// Convert from a pixel&#39;s x, y coordinates to its section index
    /// This is a helper function
    function getSectionIndexFromRaw(
        uint _x,
        uint _y
    ) returns (uint) {
        if (_x >= mapWidth) throw;
        if (_y >= mapHeight) throw;
        // Convert raw x, y to section identifer x y
        _x = _x / 10;
        _y = _y / 10;
        //Get section_identifier from coords
        return _x + (_y * 100);
    }

    /* Get the index to access a section object from its section identifier */
    /// Get Section index based on its upper left x,y coordinates or "identifier"
    /// coordinates
    /// This is a helper function
    function getSectionIndexFromIdentifier (
        uint _x_section_identifier,
        uint _y_section_identifier
    ) returns (uint) {
        if (_x_section_identifier >= (mapWidth / 10)) throw;
        if (_y_section_identifier >= (mapHeight / 10)) throw;
        uint index = _x_section_identifier + (_y_section_identifier * 100);
        return index;
    }

    /* Get x,y section_identifier from a section index */
    /// Get Section upper left x,y coordinates or "identifier" coordinates
    /// based on its index number
    /// This is a helper function
    function getIdentifierFromSectionIndex(
        uint _index
    ) returns (uint x, uint y) {
        if (_index > (mapWidth * mapHeight)) throw;
        x = _index % 100;
        y = (_index - (_index % 100)) / 100;
    }

    /* Check to see if Section is available for first purchase */
    /// Returns whether a section is available for purchase at IPO price
    function sectionAvailable(
        uint _section_index
    ) returns (bool) {
        if (_section_index >= sections.length) throw;
        Section s = sections[_section_index];
        // The section has not been puchased previously
        return !s.initial_purchase_done;
    }

    /* Check to see if Section is available for purchase */
    /// Returns whether a section is available for purchase as a market sale
    function sectionForSale(
        uint _section_index
    ) returns (bool) {
        if (_section_index >= sections.length) throw;
        Section s = sections[_section_index];
        // Has the user set the section as for_sale
        if(s.for_sale)
        {
            // Has the owner set a "sell only to" address?
            if(s.sell_only_to == 0x0) return true;
            if(s.sell_only_to == msg.sender) return true;
            return false;
        }
        else
        {
            // Not for sale
            return false;
        }
    }

    /* Get the price of the Section */
    /// Returns the price of a section at market price.
    /// This is a helper function, it is more efficient to just access the
    /// contract&#39;s sections attribute directly
    function sectionPrice(
        uint _section_index
    ) returns (uint) {
        if (_section_index >= sections.length) throw;
        Section s = sections[_section_index];
        return s.price;
    }

    /*
    Check to see if a region is available provided the
    top-left (start) section and the bottom-right (end)
    section.
    */
    /// Returns if a section is available for purchase, it returns the following:
    /// bool: if the region is available for purchase
    /// uint256: the extended price, sum of all of the market prices of the sections
    ///   in the region
    /// uint256: the number of sections available in the region at the IPO price
    function regionAvailable(
        uint _start_section_index,
        uint _end_section_index
    ) returns (bool available, uint extended_price, uint ipo_count) {
        if (_end_section_index < _start_section_index) throw;
        var (start_x, start_y) = getIdentifierFromSectionIndex(_start_section_index);
        var (end_x, end_y) = getIdentifierFromSectionIndex(_end_section_index);
        if (start_x >= mapWidth) throw;
        if (start_y >= mapHeight) throw;
        if (end_x >= mapWidth) throw;
        if (end_y >= mapHeight) throw;
        uint y_pos = start_y;
        available = false;
        extended_price = 0;
        ipo_count = 0;
        while (y_pos <= end_y)
        {
            uint x_pos = start_x;
            while (x_pos <= end_x)
            {
                uint identifier = (x_pos + (y_pos * 100));
                // Is this section available for first (IPO) purchase?
                if(sectionAvailable(identifier))
                {
                    // The section is available as an IPO
                    ipo_count = ipo_count + 1;
                } else
                {
                    // The section has been purchased, it can only be available
                    // as a market sale.
                    if(sectionForSale(identifier))
                    {
                        extended_price = extended_price + sectionPrice(identifier);
                    } else
                    {
                        available = false;
                        //Don&#39;t return a price if there is an unavailable section
                        //to reduce confusion
                        extended_price = 0;
                        ipo_count = 0;
                        return;
                    }
                }
                x_pos = x_pos + 1;
            }
            y_pos = y_pos + 1;
        }
        available = true;
        return;
    }

    /// Buy a section based on its index and set its cloud image_id and md5
    /// This function is payable, any over payment will be withdraw-able
    function buySection (
        uint _section_index,
        uint _image_id,
        string _md5
    ) payable {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(!section.for_sale && section.initial_purchase_done)
        {
            //Section not for sale
            throw;
        }
        // Process payment
        // Is this Section on the open market?
        if(section.initial_purchase_done)
        {
            // Section sold, sell for market price
            if(msg.value < section.price)
            {
                // Not enough funds were sent
                throw;
            } else
            {
                // Calculate Fee
                // We only need to change the balance if the section price is non-zero
                if (section.price != 0)
                {
                    uint fee = section.price / 100;
                    // Pay contract owner the fee
                    ethBalance[owner] += fee;
                    // Pay the section owner the price minus the fee
                    ethBalance[section.owner] += (msg.value - fee);
                }
                // Refund any overpayment
                //require(msg.value > (msg.value - section.price));
                ethBalance[msg.sender] += (msg.value - section.price);
                // Owner loses a token
                balanceOf[section.owner]--;
                // Buyer gets a token
                balanceOf[msg.sender]++;
            }
        } else
        {
            // Initial sale, sell for IPO price
            if(msg.value < ipo_price)
            {
                // Not enough funds were sent
                throw;
            } else
            {
                // Pay the contract owner
                ethBalance[owner] += msg.value;
                // Refund any overpayment
                //require(msg.value > (msg.value - ipo_price));
                ethBalance[msg.sender] += (msg.value - ipo_price);
                // Reduce token pool
                pool--;
                // Buyer gets a token
                balanceOf[msg.sender]++;
            }
        }
        //Payment and token transfer complete
        //Transfer ownership and set not for sale by default
        section.owner = msg.sender;
        section.md5 = _md5;
        section.image_id = _image_id;
        section.last_update = block.timestamp;
        section.for_sale = false;
        section.initial_purchase_done = true; // even if not the first, we can pretend it is
    }

    /* Buy an entire region */
    /// Buy a region of sections starting and including the top left section index
    /// ending at and including the bottom left section index. And set its cloud
    /// image_id and md5. This function is payable, if the value sent is less
    /// than the price of the region, the function will throw.
    function buyRegion(
        uint _start_section_index,
        uint _end_section_index,
        uint _image_id,
        string _md5
    ) payable returns (uint start_section_y, uint start_section_x,
    uint end_section_y, uint end_section_x){
        if (_end_section_index < _start_section_index) throw;
        if (_start_section_index >= sections.length) throw;
        if (_end_section_index >= sections.length) throw;
        // ico_ammount reffers to the number of sections that are available
        // at ICO price
        var (available, ext_price, ico_amount) = regionAvailable(_start_section_index, _end_section_index);
        if (!available) throw;

        // Calculate price
        uint area_price =  ico_amount * ipo_price;
        area_price = area_price + ext_price;
        AreaPrice(_start_section_index, _end_section_index, area_price);
        SentValue(msg.value);
        if (area_price > msg.value) throw;

        // ico_ammount reffers to the amount in wei that the contract owner
        // is owed
        ico_amount = 0;
        // ext_price reffers to the amount in wei that the contract owner is
        // owed in fees from market sales
        ext_price = 0;

        // User sent enough funds, let&#39;s go
        start_section_x = _start_section_index % 100;
        end_section_x = _end_section_index % 100;
        start_section_y = _start_section_index - (_start_section_index % 100);
        start_section_y = start_section_y / 100;
        end_section_y = _end_section_index - (_end_section_index % 100);
        end_section_y = end_section_y / 100;
        uint x_pos = start_section_x;
        while (x_pos <= end_section_x)
        {
            uint y_pos = start_section_y;
            while (y_pos <= end_section_y)
            {
                // Is this an IPO section?
                Section s = sections[x_pos + (y_pos * 100)];
                if (s.initial_purchase_done)
                {
                    // Sale, we need to transfer balance
                    // We only need to modify balances if the section&#39;s price
                    // is non-zero
                    if(s.price != 0)
                    {
                        // Pay the contract owner the price
                        ethBalance[owner] += (s.price / 100);
                        // Pay the owner the price minus the fee
                        ethBalance[s.owner] += (s.price - (s.price / 100));
                    }
                    // Refund any overpayment
                    //if(msg.value > (msg.value - s.price)) throw;
                    ext_price += s.price;
                    // Owner loses a token
                    balanceOf[s.owner]--;
                    // Buyer gets a token
                    balanceOf[msg.sender]++;
                } else
                {
                    // IPO we get to keep the value
                    // Pay the contract owner
                    ethBalance[owner] += ipo_price;
                    // Refund any overpayment
                    //if(msg.value > (msg.value - ipo_price)) throw;
                    // TODO Decrease the value
                    ico_amount += ipo_price;
                    // Reduce token pool
                    pool--;
                    // Buyer gets a token
                    balanceOf[msg.sender]++;
                }

                // Payment and token transfer complete
                // Transfer ownership and set not for sale by default
                s.owner = msg.sender;
                s.md5 = _md5;
                s.image_id = _image_id;
                //s.last_update = block.timestamp;
                s.for_sale = false;
                s.initial_purchase_done = true; // even if not the first, we can pretend it is

                Buy(x_pos + (y_pos * 100));
                // Done
                y_pos = y_pos + 1;
            }
            x_pos = x_pos + 1;
        }
        ethBalance[msg.sender] += msg.value - (ext_price + ico_amount);
        return;
    }

    /* Set the for sale flag and a price for a section */
    /// Set an inidividual section as for sale at the provided price in wei.
    /// The section will be available for purchase by any address.
    function setSectionForSale(
        uint _section_index,
        uint256 _price
    ) {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(section.owner != msg.sender) throw;
        section.price = _price;
        section.for_sale = true;
        section.sell_only_to = 0x0;
        NewListing(_section_index, _price);
    }

    /* Set the for sale flag and price for a region */
    /// Set a section region for sale at the provided price in wei.
    /// The sections in the region will be available for purchase by any address.
    function setRegionForSale(
        uint _start_section_index,
        uint _end_section_index,
        uint _price
    ) {
        if(_start_section_index > _end_section_index) throw;
        if(_end_section_index > 9999) throw;
        uint x_pos = _start_section_index % 100;
        uint base_y_pos = (_start_section_index - (_start_section_index % 100)) / 100;
        uint x_max = _end_section_index % 100;
        uint y_max = (_end_section_index - (_end_section_index % 100)) / 100;
        while(x_pos <= x_max)
        {
            uint y_pos = base_y_pos;
            while(y_pos <= y_max)
            {
                Section section = sections[x_pos + (y_pos * 100)];
                if(section.owner == msg.sender)
                {
                    section.price = _price;
                    section.for_sale = true;
                    section.sell_only_to = 0x0;
                    NewListing(x_pos + (y_pos * 100), _price);
                }
                y_pos++;
            }
            x_pos++;
        }
    }

    /* Set the for sale flag and price for a region */
    /// Set a section region starting in the top left at the supplied start section
    /// index to and including the supplied bottom right end section index
    /// for sale at the provided price in wei, to the provided address.
    /// The sections in the region will be available for purchase only by the
    /// provided address.
    function setRegionForSaleToAddress(
        uint _start_section_index,
        uint _end_section_index,
        uint _price,
        address _only_sell_to
    ) {
        if(_start_section_index > _end_section_index) throw;
        if(_end_section_index > 9999) throw;
        uint x_pos = _start_section_index % 100;
        uint base_y_pos = (_start_section_index - (_start_section_index % 100)) / 100;
        uint x_max = _end_section_index % 100;
        uint y_max = (_end_section_index - (_end_section_index % 100)) / 100;
        while(x_pos <= x_max)
        {
            uint y_pos = base_y_pos;
            while(y_pos <= y_max)
            {
                Section section = sections[x_pos + (y_pos * 100)];
                if(section.owner == msg.sender)
                {
                    section.price = _price;
                    section.for_sale = true;
                    section.sell_only_to = _only_sell_to;
                    NewListing(x_pos + (y_pos * 100), _price);
                }
                y_pos++;
            }
            x_pos++;
        }
    }

    /*
    Set an entire region&#39;s cloud image data
    */
    /// Update a region of sections&#39; cloud image_id and md5 to be redrawn on the
    /// map starting at the top left start section index to and including the
    /// bottom right section index. Fires a NewImage event with the top left
    /// section index. If any sections not owned by the sender are in the region
    /// they are ignored.
    function setRegionImageDataCloud(
        uint _start_section_index,
        uint _end_section_index,
        uint _image_id,
        string _md5
    ) {
        if (_end_section_index < _start_section_index) throw;
        var (start_x, start_y) = getIdentifierFromSectionIndex(_start_section_index);
        var (end_x, end_y) = getIdentifierFromSectionIndex(_end_section_index);
        if (start_x >= mapWidth) throw;
        if (start_y >= mapHeight) throw;
        if (end_x >= mapWidth) throw;
        if (end_y >= mapHeight) throw;
        uint y_pos = start_y;
        while (y_pos <= end_y)
        {
            uint x_pos = start_x;
            while (x_pos <= end_x)
            {
                uint identifier = (x_pos + (y_pos * 100));
                Section s = sections[identifier];
                if(s.owner == msg.sender)
                {
                    s.image_id = _image_id;
                    s.md5 = _md5;
                }
                x_pos = x_pos + 1;
            }
            y_pos = y_pos + 1;
        }
        NewImage(_start_section_index);
        return;
    }

    /* Set the for sale flag and a price for a section to a specific address */
    /// Set a single section as for sale at the provided price in wei only
    /// to the supplied address.
    function setSectionForSaleToAddress(
        uint _section_index,
        uint256 _price,
        address _to
    ) {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(section.owner != msg.sender) throw;
        section.price = _price;
        section.for_sale = true;
        section.sell_only_to = _to;
        NewListing(_section_index, _price);
    }

    /* Remove the for sale flag from a section */
    /// Delist a section for sale. Making it no longer available on the market.
    function unsetSectionForSale(
        uint _section_index
    ) {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(section.owner != msg.sender) throw;
        section.for_sale = false;
        section.price = 0;
        section.sell_only_to = 0x0;
        Delisted(_section_index);
    }

    /* Set the for sale flag and price for a region */
    /// Delist a region of sections for sale. Making the sections no longer
    /// no longer available on the market.
    function unsetRegionForSale(
        uint _start_section_index,
        uint _end_section_index
    ) {
        if(_start_section_index > _end_section_index) throw;
        if(_end_section_index > 9999) throw;
        uint x_pos = _start_section_index % 100;
        uint base_y_pos = (_start_section_index - (_start_section_index % 100)) / 100;
        uint x_max = _end_section_index % 100;
        uint y_max = (_end_section_index - (_end_section_index % 100)) / 100;
        while(x_pos <= x_max)
        {
            uint y_pos = base_y_pos;
            while(y_pos <= y_max)
            {
                Section section = sections[x_pos + (y_pos * 100)];
                if(section.owner == msg.sender)
                {
                    section.for_sale = false;
                    section.price = 0;
                    Delisted(x_pos + (y_pos * 100));
                }
                y_pos++;
            }
            x_pos++;
        }
    }

    /// Depreciated. Store the raw image data in the contract.
    function setImageData(
        uint _section_index
        // bytes32 _row_zero,
        // bytes32 _row_one,
        // bytes32 _row_two,
        // bytes32 _row_three,
        // bytes32 _row_four,
        // bytes32 _row_five,
        // bytes32 _row_six,
        // bytes32 _row_seven,
        // bytes32 _row_eight,
        // bytes32 _row_nine
    ) {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(section.owner != msg.sender) throw;
        // section.image_data[0] = _row_zero;
        // section.image_data[1] = _row_one;
        // section.image_data[2] = _row_two;
        // section.image_data[3] = _row_three;
        // section.image_data[4] = _row_four;
        // section.image_data[5] = _row_five;
        // section.image_data[6] = _row_six;
        // section.image_data[7] = _row_seven;
        // section.image_data[8] = _row_eight;
        // section.image_data[9] = _row_nine;
        section.image_id = 0;
        section.md5 = "";
        section.last_update = block.timestamp;
        NewImage(_section_index);
    }

    /// Set a section&#39;s image data to be redrawn on the map. Fires a NewImage
    /// event.
    function setImageDataCloud(
        uint _section_index,
        uint _image_id,
        string _md5
    ) {
        if (_section_index >= sections.length) throw;
        Section section = sections[_section_index];
        if(section.owner != msg.sender) throw;
        section.image_id = _image_id;
        section.md5 = _md5;
        section.last_update = block.timestamp;
        NewImage(_section_index);
    }

    /// Withdraw ethereum from the sender&#39;s ethBalance.
    function withdraw() returns (bool) {
        var amount = ethBalance[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            ethBalance[msg.sender] = 0;
            WithdrawEvent("Reset Sender");
            msg.sender.transfer(amount);
        }
        return true;
    }

    /// Deposit ethereum into the sender&#39;s ethBalance. Not recommended.
    function deposit() payable
    {
        ethBalance[msg.sender] += msg.value;
    }

    /// Transfer a section and an IPO token to the supplied address.
    function transfer(
      address _to,
      uint _section_index
    ) {
        if (_section_index > 9999) throw;
        if (sections[_section_index].owner != msg.sender) throw;
        if (balanceOf[_to] + 1 < balanceOf[_to]) throw;
        sections[_section_index].owner = _to;
        sections[_section_index].for_sale = false;
        balanceOf[msg.sender] -= 1;
        balanceOf[_to] += 1;
    }



    /// Transfer a region of sections and IPO tokens to the supplied address.
    function transferRegion(
        uint _start_section_index,
        uint _end_section_index,
        address _to
    ) {
        if(_start_section_index > _end_section_index) throw;
        if(_end_section_index > 9999) throw;
        uint x_pos = _start_section_index % 100;
        uint base_y_pos = (_start_section_index - (_start_section_index % 100)) / 100;
        uint x_max = _end_section_index % 100;
        uint y_max = (_end_section_index - (_end_section_index % 100)) / 100;
        while(x_pos <= x_max)
        {
            uint y_pos = base_y_pos;
            while(y_pos <= y_max)
            {
                Section section = sections[x_pos + (y_pos * 100)];
                if(section.owner == msg.sender)
                {
                  if (balanceOf[_to] + 1 < balanceOf[_to]) throw;
                  section.owner = _to;
                  section.for_sale = false;
                  balanceOf[msg.sender] -= 1;
                  balanceOf[_to] += 1;
                }
                y_pos++;
            }
            x_pos++;
        }
    }
}