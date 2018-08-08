pragma solidity ^0.4.13;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract EthPlot is Ownable {

    /// @dev Represents a single plot (rectangle) which is owned by someone. Additionally, it contains an array
    /// of holes which point to other PlotOwnership structs which overlap this one (and purchased a chunk of this one)
    /// 4 24 bit numbers for + 1 address = 256 bits for storage efficiency
    struct PlotOwnership {

        // Coordinates of the plot rectangle
        uint24 x;
        uint24 y;
        uint24 w;
        uint24 h;

        // The owner of the plot
        address owner;
    }

    /// @dev Represents the data which a specific plot ownership has
    struct PlotData {
        string ipfsHash;
        string url;
    }

    //----------------------State---------------------//

    // The actual coordinates and owners of plots. This array will contain all of the owned plots, with the more recent (and valid)
    // ownership plots at the top. The other state variables point to indexes in this array
    PlotOwnership[] private ownership;

    // Maps from the index in the ownership array to the data for this particular plot (its image and website)
    mapping(uint256 => PlotData) private data;

    // Maps plot ID to a boolean that represents whether or not
    // the image of the plot might be illegal and need to be blocked
    // in the UI of Eth Plot. Defaults to false.
    mapping (uint256 => bool) private plotBlockedTags;

    // Maps plot ID to the plot&#39;s current price price. If price is 0, the plot is not for sale. Price is Wei per pixel.
    mapping(uint256 => uint256) private plotIdToPrice;

    // Maps plot ID to other plots IDs which which have purchased sections of this plot (a hole).
    // Once a plot has been completely re-purchased, these holes will completely tile over the plot.
    mapping(uint256 => uint256[]) private holes;
    
    //----------------------Constants---------------------//
    uint24 constant private GRID_WIDTH = 250;
    uint24 constant private GRID_HEIGHT = 250;
    uint256 constant private INITIAL_PLOT_PRICE = 20000 * 1000000000; // 20000 gwei (approx. $0.01)

    // This is the maximum area of a single purchase block. This needs to be limited for the
    // algorithm which figures out payment to function
    uint256 constant private MAXIMUM_PURCHASE_AREA = 1000;
      
    //----------------------Events---------------------//

    /// @notice Inicates that a user has updated the price of their plot
    /// @param plotId The index in the ownership array which was updated
    /// @param newPriceInWeiPerPixel The new price of the plotId
    /// @param owner The current owner of the plot
    event PlotPriceUpdated(uint256 plotId, uint256 newPriceInWeiPerPixel, address indexed owner);

    /// @notice Indicates that a new plot has been purchased and added to the ownership array
    /// @param newPlotId The id (index in the ownership array) of the new plot
    /// @param totalPrice The total price paid in wei to all the plots which used to own this area
    /// @param buyer The account which made the purchase 
    event PlotPurchased(uint256 newPlotId, uint256 totalPrice, address indexed buyer);

    /// @notice Indicates that a section of a plot was purchased. Multiple PlotSectionSold events could be emitted from
    /// a single purchase transaction
    /// @param plotId The id (index in the ownership array) of the plot which had a section of it purchased
    /// @param totalPrice The total price which was paid for this section
    /// @param buyer The buyer of the section of the plot
    /// @param seller The owner of the plot which was purchased. This is who will receive totalPrice in their account
    event PlotSectionSold(uint256 plotId, uint256 totalPrice, address indexed buyer, address indexed seller);

    /// @notice Creates a new instance of the EthPlot contract. It assigns an initial ownership plot consisting of the entire grid
    /// to the creator of the contract who will also receive any transaction fees.
    constructor() public payable {
        // Initialize the contract with a single block which the admin owns
        ownership.push(PlotOwnership(0, 0, GRID_WIDTH, GRID_HEIGHT, owner));
        data[0] = PlotData("Qmb51AikiN8p6JsEcCZgrV4d7C6d6uZnCmfmaT15VooUyv/img.svg", "https://www.ethplot.com/");
        plotIdToPrice[0] = INITIAL_PLOT_PRICE;
    }

    //---------------------- External  and Public Functions ---------------------//

    /// @notice Purchases a new plot with at the location (`purchase[0]`,`purchase[1]`) and dimensions `purchase[2]`x`purchase[2]`.
    /// The new plot will have the data stored at ipfs hash `ipfsHash` and a website of `url`
    /// @dev This function is the way you purchase new plots from the chain. The data is specified in a somewhat unique format to
    /// make the execution of the contract as efficient as possible. Essentially, the caller needs to send in an array of sub-plots which
    /// form a complete tiling of the purchased area. These sub-plots represent sections of the already existing plots this purchase is
    /// happening on top of. The contract will validate all of this data before allowing the purchase to proceed.
    /// @param purchase An array of exactly 4 values which represent the [x,y,width,height] of the plot to purchase
    /// @param purchasedAreas An array of at least 4 values. Each set of 4 values represents a sub-plot which must be purchased for this
    /// plot to be created. If the new plot to purchase overlaps in a non-rectangle pattern, multiple rectangular sub-plots from that
    /// plot can be specified. The sub-plots must be from existing plots in descending order of that plot&#39;s index
    /// @param areaIndices An area of indices into the ownership array which represent which plot the rectangles in purchasedAreas are
    /// coming from. Must be equal to 1/4 the length of purchasedAreas
    /// @param ipfsHash The hash of the image data for this plot stored in ipfs
    /// @param url The website / url which should be associated with this plot
    /// @param initialBuyoutPriceInWeiPerPixel The price per pixel a future buyer would have to pay to purchase an area of this plot.
    /// Set a price of 0 to mark that this plot is not for sale
    function purchaseAreaWithData(
        uint24[] purchase,
        uint24[] purchasedAreas,
        uint256[] areaIndices,
        string ipfsHash,
        string url,
        uint256 initialBuyoutPriceInWeiPerPixel) external payable {
        
        // Validate that all of the data makes sense and is valid, then payout the plot sellers
        uint256 initialPurchasePrice = validatePurchaseAndDistributeFunds(purchase, purchasedAreas, areaIndices);

        // After we&#39;ve validated that this purchase is valid, actually put the new plot and info in storage locations
        uint256 newPlotIndex = addPlotAndData(purchase, ipfsHash, url, initialBuyoutPriceInWeiPerPixel);

        // Now that purchase is completed, update plots that have new holes due to this purchase
        for (uint256 i = 0; i < areaIndices.length; i++) {
            holes[areaIndices[i]].push(newPlotIndex);
        }

        // Finally, emit an event to indicate that this purchase happened
        emit PlotPurchased(newPlotIndex, initialPurchasePrice, msg.sender);
    }

    /// @notice Updates the price per pixel of a plot which the message sender owns. A price of 0 means the plot is not for sale
    /// @param plotIndex The index in the ownership array which we are updating. msg.sender must be the owner of this plot
    /// @param newPriceInWeiPerPixel The new price of the plot
    function updatePlotPrice(uint256 plotIndex, uint256 newPriceInWeiPerPixel) external {
        require(plotIndex >= 0);
        require(plotIndex < ownership.length);
        require(msg.sender == ownership[plotIndex].owner);

        plotIdToPrice[plotIndex] = newPriceInWeiPerPixel;
        emit PlotPriceUpdated(plotIndex, newPriceInWeiPerPixel, msg.sender);
    }

    /// @notice Updates the data for a specific plot. This is only allowed by the plot&#39;s owner
    /// @param plotIndex The index in the ownership array which we are updating. msg.sender must be the owner of this plot
    /// @param ipfsHash The hash of the image data for this plot stored in ipfs
    /// @param url The website / url which should be associated with this plot
    function updatePlotData(uint256 plotIndex, string ipfsHash, string url) external {
        require(plotIndex >= 0);
        require(plotIndex < ownership.length);
        require(msg.sender == ownership[plotIndex].owner);

        data[plotIndex] = PlotData(ipfsHash, url);
    }

    // ---------------------- Public Admin Functions ---------------------//
    
    /// @notice Withdraws the fees which have been collected back to the contract owner, who is the only person that can call this
    /// @param transferTo Who the transfer should go to. This must be the admin, but we pass it as a parameter to prevent a frontrunning
    /// issue if we change ownership of the contract.
    function withdraw(address transferTo) onlyOwner external {
        // Prevent https://consensys.github.io/smart-contract-best-practices/known_attacks/#transaction-ordering-dependence-tod-front-running
        require(transferTo == owner);

        uint256 currentBalance = address(this).balance;
        owner.transfer(currentBalance);
    }

    /// @notice Sets whether or not the image data in a plot should be blocked from the EthPlot UI. This is used to take down
    /// illegal content if needed. The image data is not actually deleted, just no longer visible in the UI
    /// @param plotIndex The index in the ownership array where the illegal data is located
    /// @param plotBlocked Whether or not this data should be blocked
    function togglePlotBlockedTag(uint256 plotIndex, bool plotBlocked) onlyOwner external {
        require(plotIndex >= 0);
        require(plotIndex < ownership.length);
        plotBlockedTags[plotIndex] = plotBlocked;
    }

    // ---------------------- Public View Functions ---------------------//

    /// @notice Gets the information for a specific plot based on its index.
    /// @dev Due to stack too deep issues, to get all the info about a plot, you must also call getPlotData in conjunction with this
    /// @param plotIndex The index in the ownership array to get the plot info for
    /// @return The coordinates of this plot, the owner address, and the current buyout price of it (0 if not for sale)
    function getPlotInfo(uint256 plotIndex) public view returns (uint24 x, uint24 y, uint24 w , uint24 h, address owner, uint256 price) {
        require(plotIndex < ownership.length);
        return (
            ownership[plotIndex].x,
            ownership[plotIndex].y,
            ownership[plotIndex].w,
            ownership[plotIndex].h,
            ownership[plotIndex].owner,
            plotIdToPrice[plotIndex]);
    }

    /// @notice Gets the data stored with a specific plot. This includes the website, ipfs hash, and the blocked status of the image
    /// @dev Due to stack too deep issues, to get all the info about a plot, you must also call getPlotInfo in conjunction with this
    /// @param plotIndex The index in the ownership array to get the plot data for
    /// @return The ipfsHash of the plot&#39;s image, the website associated with the plot, and whether or not its image is blocked
    function getPlotData(uint256 plotIndex) public view returns (string ipfsHash, string url, bool plotBlocked) {
        require(plotIndex < ownership.length);
        return (data[plotIndex].url, data[plotIndex].ipfsHash, plotBlockedTags[plotIndex]);
    }
    
    /// @notice Gets the length of the ownership array which represents the number of owned plots which exist
    /// @return The number of plots which are owned on the grid
    function ownershipLength() public view returns (uint256) {
        return ownership.length;
    }
    
    //---------------------- Private Functions ---------------------//

    /// @notice This function does a lot of the heavy lifting for validating that all of the data passed in to the purchase function is ok.
    /// @dev It works by first validating all of the inputs and converting purchase and purchasedAreas into rectangles for easier manipulation.
    /// Next, it validates that all of the rectangles in purchasedArea are within the area to purchase, and that they form a complete tiling of
    /// the purchase we are making with zero overlap. Next, to prevent stack too deep errors, it delegates the work of validating that these sub-plots
    /// are actually for sale, are valid, and pays out the previous owners of the area.
    /// @param purchase An array of exactly 4 values which represent the [x,y,width,height] of the plot to purchase
    /// @param purchasedAreas An array of at least 4 values. Each set of 4 values represents a sub-plot which must be purchased for this
    /// plot to be created.
    /// @param areaIndices An area of indices into the ownership array which represent which plot the rectangles in purchasedAreas are from
    /// @return The amount spent to purchase all of the subplots specified in purchasedAreas
    function validatePurchaseAndDistributeFunds(uint24[] purchase, uint24[] purchasedAreas, uint256[] areaIndices) private returns (uint256) {
        // Validate that we were given a valid area to purchase
        require(purchase.length == 4);
        Geometry.Rect memory plotToPurchase = Geometry.Rect(purchase[0], purchase[1], purchase[2], purchase[3]);
        
        require(plotToPurchase.x < GRID_WIDTH && plotToPurchase.x >= 0);
        require(plotToPurchase.y < GRID_HEIGHT && plotToPurchase.y >= 0);

        // No need for SafeMath here because we know plotToPurchase.x & plotToPurchase.y are less than 250 (~2^8)
        require(plotToPurchase.w > 0 && plotToPurchase.w + plotToPurchase.x <= GRID_WIDTH);
        require(plotToPurchase.h > 0 && plotToPurchase.h + plotToPurchase.y <= GRID_HEIGHT);
        require(plotToPurchase.w * plotToPurchase.h < MAXIMUM_PURCHASE_AREA);

        // Validate the purchasedAreas and the purchasedArea&#39;s indices
        require(purchasedAreas.length >= 4);
        require(areaIndices.length > 0);
        require(purchasedAreas.length % 4 == 0);
        require(purchasedAreas.length / 4 == areaIndices.length);

        // Build up an array of subPlots which represent all of the sub-plots we are purchasing
        Geometry.Rect[] memory subPlots = new Geometry.Rect[](areaIndices.length);

        uint256 totalArea = 0;
        uint256 i = 0;
        uint256 j = 0;
        for (i = 0; i < areaIndices.length; i++) {
            // Define the rectangle and add it to our collection of them
            Geometry.Rect memory rect = Geometry.Rect(
                purchasedAreas[(i * 4)], purchasedAreas[(i * 4) + 1], purchasedAreas[(i * 4) + 2], purchasedAreas[(i * 4) + 3]);
            subPlots[i] = rect;

            require(rect.w > 0);
            require(rect.h > 0);

            // Compute the area of this rect and add it to the total area
            totalArea = SafeMath.add(totalArea, SafeMath.mul(rect.w,rect.h));

            // Verify that this rectangle is within the bounds of the area we are trying to purchase
            require(Geometry.rectContainedInside(rect, plotToPurchase));
        }

        require(totalArea == plotToPurchase.w * plotToPurchase.h);

        // Next, make sure all of these do not overlap
        for (i = 0; i < subPlots.length; i++) {
            for (j = i + 1; j < subPlots.length; j++) {
                require(!Geometry.doRectanglesOverlap(subPlots[i], subPlots[j]));
            }
        }

        // If we have a matching area, the subPlots are all contained within what we&#39;re purchasing, and none of them overlap,
        // we know we have a complete tiling of the plotToPurchase. Next, validate we can purchase all of these and distribute funds
        uint256 remainingBalance = checkHolesAndDistributePurchaseFunds(subPlots, areaIndices);
        uint256 purchasePrice = SafeMath.sub(msg.value, remainingBalance);
        return purchasePrice;
    }

    /// @notice Checks that the sub-plots which we are purchasing are all valid and then distributes funds to the owners of those sub-plots
    /// @dev Since we know that the subPlots are contained within plotToPurchase, and that they don&#39;t overlap, we just need go through each one
    /// and make sure that it is for sale and owned by the appropriate person as specified in areaIndices. We then can calculate how much to
    /// pay out for the sub-plot as well.
    /// @param subPlots Array of sub-plots which tiles the plotToPurchase completely
    /// @param areaIndices Array of indices into the ownership array which correspond to who owns the subPlot at the same index of subPlots.
    /// The array must be the same length as subPlots and go in descending order
    /// @return The balance still remaining from the original msg.value after paying out all of the owners of the subPlots
    function checkHolesAndDistributePurchaseFunds(Geometry.Rect[] memory subPlots, uint256[] memory areaIndices) private returns (uint256) {

        // Initialize the remaining balance to the value which was passed in here
        uint256 remainingBalance = msg.value;

        // In order to minimize calls to transfer(), aggregate how much is owed to a single plot owner for all of their subPlots (this is 
        // useful in the case that the buyer is overlaping with a single plot in a non-rectangular manner)
        uint256 owedToSeller = 0;

        for (uint256 areaIndicesIndex = 0; areaIndicesIndex < areaIndices.length; areaIndicesIndex++) {

            // Get information about the plot at this index
            uint256 ownershipIndex = areaIndices[areaIndicesIndex];
            Geometry.Rect memory currentOwnershipRect = Geometry.Rect(
                ownership[ownershipIndex].x, ownership[ownershipIndex].y, ownership[ownershipIndex].w, ownership[ownershipIndex].h);

            // This is a plot the caller has declared they were going to buy. We need to verify that the subPlot is fully contained inside 
            // the current ownership plot we are dealing with (we already know the subPlot is inside the plot to purchase)
            require(Geometry.rectContainedInside(subPlots[areaIndicesIndex], currentOwnershipRect));

            // Next, verify that none of the holes of this plot ownership overlap with what we are trying to purchase
            for (uint256 holeIndex = 0; holeIndex < holes[ownershipIndex].length; holeIndex++) {
                PlotOwnership memory holePlot = ownership[holes[ownershipIndex][holeIndex]];
                Geometry.Rect memory holeRect = Geometry.Rect(holePlot.x, holePlot.y, holePlot.w, holePlot.h);

                require(!Geometry.doRectanglesOverlap(subPlots[areaIndicesIndex], holeRect));
            }

            // Finally, add the price of this rect to the totalPrice computation
            uint256 sectionPrice = getPriceOfPlot(subPlots[areaIndicesIndex], ownershipIndex);
            remainingBalance = SafeMath.sub(remainingBalance, sectionPrice);
            owedToSeller = SafeMath.add(owedToSeller, sectionPrice);

            // If this is the last one to look at, or if the next ownership index is different, payout this owner
            if (areaIndicesIndex == areaIndices.length - 1 || ownershipIndex != areaIndices[areaIndicesIndex + 1]) {

                // Update the balances and emit an event to indicate the chunks of this plot which were sold
                address(ownership[ownershipIndex].owner).transfer(owedToSeller);
                emit PlotSectionSold(ownershipIndex, owedToSeller, msg.sender, ownership[ownershipIndex].owner);
                owedToSeller = 0;
            }
        }
        
        return remainingBalance;
    }

    /// @notice Given a rect to purchase and the plot index, return the total price to be paid. Requires that the plot is for sale
    /// @param subPlotToPurchase The subplot of plotIndex which we want to compute the price of
    /// @param plotIndex The index in the ownership array for this plot
    /// @return The price that must be paid for this subPlot
    function getPriceOfPlot(Geometry.Rect memory subPlotToPurchase, uint256 plotIndex) private view returns (uint256) {

        // Verify that this plot exists in the plot price mapping with a price.
        uint256 plotPricePerPixel = plotIdToPrice[plotIndex];
        require(plotPricePerPixel > 0);

        return SafeMath.mul(SafeMath.mul(subPlotToPurchase.w, subPlotToPurchase.h), plotPricePerPixel);
    }

    /// @notice Stores the plot information and data for a newly purchased plot.
    /// @dev All parameters are assumed to be validated before calling
    /// @param purchase The coordinates of the plot to purchase
    /// @param ipfsHash The hash of the image data for this plot stored in ipfs
    /// @param url The website / url which should be associated with this plot
    /// @param initialBuyoutPriceInWeiPerPixel The price per pixel a future buyer would have to pay to purchase an area of this plot.
    /// @return The index in the plotOwnership array where this plot was placed
    function addPlotAndData(uint24[] purchase, string ipfsHash, string url, uint256 initialBuyoutPriceInWeiPerPixel) private returns (uint256) {
        uint256 newPlotIndex = ownership.length;

        // Add the new ownership to the array
        ownership.push(PlotOwnership(purchase[0], purchase[1], purchase[2], purchase[3], msg.sender));

        // Take in the input data for the actual grid!
        data[newPlotIndex] = PlotData(ipfsHash, url);

        // Set an initial purchase price for the new plot if it&#39;s greater than 0
        if (initialBuyoutPriceInWeiPerPixel > 0) {
            plotIdToPrice[newPlotIndex] = initialBuyoutPriceInWeiPerPixel;
        }

        return newPlotIndex;
    }
}

library Geometry {
    struct Rect {
        uint24 x;
        uint24 y;
        uint24 w;
        uint24 h;
    }

    function doRectanglesOverlap(Rect memory a, Rect memory b) internal pure returns (bool) {
        return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
    }

    // It is assumed that we will have called doRectanglesOverlap before calling this method and we will know they overlap
    function computeRectOverlap(Rect memory a, Rect memory b) internal pure returns (Rect memory) {
        Rect memory result = Rect(0, 0, 0, 0);

        // Take the greater of the x and y values;
        result.x = a.x > b.x ? a.x : b.x;
        result.y = a.y > b.y ? a.y : b.y;

        // Take the lesser of the x2 and y2 values
        uint24 resultX2 = a.x + a.w < b.x + b.w ? a.x + a.w : b.x + b.w;
        uint24 resultY2 = a.y + a.h < b.y + b.h ? a.y + a.h : b.y + b.h;

        // Set our width and height here
        result.w = resultX2 - result.x;
        result.h = resultY2 - result.y;

        return result;
    }

    function rectContainedInside(Rect memory inner, Rect memory outer) internal pure returns (bool) {
        return inner.x >= outer.x && inner.y >= outer.y && inner.x + inner.w <= outer.x + outer.w && inner.y + inner.h <= outer.y + outer.h;
    }
}