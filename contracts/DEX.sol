pragma solidity ^0.4.22;

contract DecentralisedExchange {
    address public owner;
    uint a = 1 finney;
    uint256 count;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    //basic set up of the userbase begins here(**)
    //struct for buyer
    struct buyer {
        string name; //aesthetic purposes
        uint requested; //how much requested(unit: Finney)
        bool buying; //bool indicating whether they are buying or not
    }
    //struct for arbitrator
    struct arbitrators {
        string name; //aesthetic purposes
        uint fee; //fee in terms of finney charged per transaction arbitrated
        uint rating; //total amount of transactions
        uint mediatedRating; //amount of transactions mediated on
        uint percentMediated; //((mediatedRatingt)/(rating)) * 100
        bool arbitrating; //bool indicating whether they are arbitrating or not
    }
    //struct for seller
    struct seller {
        string name; //aesthetic purposes
        uint rate; //rate in terms of how much extra finney charged for every ether
        uint HighestSold; //highest amount sold in a single transaction
        uint SellCount; //amount of buyers sold to
        bool selling; //bool indicating whether they are buying or not
    }

    mapping(address => seller) Sellers; //mapping of addresses to the seller struct
    address[] SellList; //list of addresses mapped to the seller struct

    //list of Seller exclusive functions begins here(***)

    //registers an address as a seller
    function registerAsSeller(string _name) external {
        assert(!checkRegistered(msg.sender, SellList)); //checks to ensure that the address doesnt already exist in registries
        SellList.push(msg.sender);
        Sellers[msg.sender].name = _name;
        //sets to defaults
        Sellers[msg.sender].rate = 100;
        Sellers[msg.sender].HighestSold = 0;
        Sellers[msg.sender].SellCount = 0;
        Sellers[msg.sender].selling = true;
    }
    //changes the rate charged(default is 100 finney)
    function changeRate(uint _rate) external {
        assert(checkRegistered(msg.sender, SellList));
        Sellers[msg.sender].rate = _rate;
    }
    //changes state from true to false and vice verca
    function changeSelling() external {
        assert(checkRegistered(msg.sender,  SellList));
        Sellers[msg.sender].selling = !Sellers[msg.sender].selling;
    }
    //ends here(***)

    mapping(address => buyer) Buyers; //mapping of addresses to the buyer struct
    address[] BuyList; //list of addresses mapped to the buyer struct

    //list of Buyer exclusive functions begins here(***)

    function registerAsBuyer(string _name, uint _requested) external {
        assert(!checkRegistered(msg.sender, BuyList)); //checks to ensure that the address doesnt already exist in registries
        BuyList.push(msg.sender);
        Buyers[msg.sender].name = _name;
        Buyers[msg.sender].requested = _requested;
        Buyers[msg.sender].buying = true;
    }

    //allows same buyer to request more
    function changeRequested(uint _requested) external {
        assert(checkRegistered(msg.sender,BuyList));
        assert(Buyers[msg.sender].requested != _requested);
        Buyers[msg.sender].requested = _requested;
    }

    //changes buy state
    function changeBuying() external {
        assert(checkRegistered(msg.sender,BuyList));
        Buyers[msg.sender].buying = !Buyers[msg.sender].buying;
    }


    //ends here(***)

    //mapping of arbitrator addresses to arbitrator struct
    mapping(address => arbitrators) Arbitrator;
    //list of addresses mapped to the struct
    address[] ArbitratorList;

    //list of arbitrator exclusive functions begins here(***)

    //registers an address as an arbitrator.
    function registerAsArbitrator(string _name, uint _fee) external {
        assert(!checkRegistered(msg.sender,ArbitratorList));
        ArbitratorList.push(msg.sender);
        Arbitrator[msg.sender].name = _name;
        Arbitrator[msg.sender].fee = _fee;
        Arbitrator[msg.sender].rating = 0;
        Arbitrator[msg.sender].mediatedRating = 0;
        Arbitrator[msg.sender].percentMediated = 0;
    }

    //changes requested fee.
    function changeFee(uint _fee) external {
        assert(checkRegistered(msg.sender, ArbitratorList));
        assert(Arbitrator[msg.sender].fee != _fee);
        Arbitrator[msg.sender].fee = _fee;
    }

    //changes whether arbitrating or not
    function changeArbitrating() external {
        assert(checkRegistered(msg.sender,ArbitratorList));
        Arbitrator[msg.sender].arbitrating = !Arbitrator[msg.sender].arbitrating;
    }

    //ends here(***)

    //used for checking of registries for the address arrays
    function checkRegistered(address app, address[] list) internal pure returns (bool) {
        bool check = false;
        for(uint i = 0; i < list.length; i++){
            if(list[i] == app){
                check = true;
            }
        }
        return check;
    }
    //ends here(**)

    struct exchange {
        uint amount;
        address sell;
        address buy;
        address arbit;
        uint status;
        uint total;
        uint timecreated;
        bool paid;
        bool buysign;
        bool sellsign;
    }

    uint256[] tokens;
    mapping(uint256 =>exchange) Exchanges;

    //beginning of transaction logic(**)

    //creates record of exchange. all transaction logic is managed using this exchange.
    function createExchange(address _sell, address _buy, uint _amount, address _arbit) external {
        require(checkRegistered(_sell, SellList));
        require(checkRegistered(_buy,BuyList));
        require(checkRegistered(_arbit,ArbitratorList));
        count++;
        tokens.push(count);
        Exchanges[count].amount = _amount;
        Exchanges[count].sell = _sell;
        Exchanges[count].buy = _buy;
        Exchanges[count].arbit = _arbit;
        Exchanges[count].status = 1;
        Exchanges[count].timecreated = now;
        Exchanges[count].paid = false;
        Exchanges[count].buysign = false;
        Exchanges[count].sellsign = false;
    }

    //1st stage of transaction logic. The seller pays the contract the amount to be transferred.
    function storeCrypto(uint256 _token) payable external {
        require(msg.sender ==  Exchanges[_token].sell);
        require(checkExchangeRegistry(_token));
        //this next line looks wordy, but what it comes down to is
        //Base amount + 1 finney for every ether(since the amount is defaulted to finney, divide by 1000 to get the eth), + arbitrators fee
        require(msg.value == (((Exchanges[_token].amount+(Sellers[Exchanges[_token].sell].rate*(Exchanges[_token].amount/1000)) + Arbitrator[Exchanges[_token].arbit].fee))/1000)*1.1 finney);
        Exchanges[_token].amount = Exchanges[_token].amount * 1 finney; //changes it into monay monay
        Exchanges[_token].status++;
    }

    //2nd stage of transaction logic. interchangable with stage 3. The buyer signs off after making the necessary arrangements to pay.
    function buyerSignOff(uint256 _token) external {
        require(msg.sender == Exchanges[_token].buy);
        require(Exchanges[_token].status > 1);
        require(checkExchangeRegistry(_token));
        require(!Exchanges[_token].buysign);
        Exchanges[_token].buysign = true;
        Exchanges[_token].status++;
        if(Exchanges[_token].status == 4) {
            transferFundsToBuyer(_token);
        }
    }

    //3rd stage. The seller signs off after recieving the money.
    function sellerSignOff(uint256 _token) external {
        require(msg.sender == Exchanges[_token].sell);
        require(Exchanges[_token].status > 1);
        require(checkExchangeRegistry(_token));
        require(!Exchanges[_token].sellsign);
        Exchanges[_token].sellsign = true;
        Exchanges[_token].status++;
        if(Exchanges[_token].status == 4) {
            transferFundsToBuyer(_token);
        }
    }

    //last stage of typical transaction. Function moves around the money to the people, then deletes the token taken up to save memory
    function transferFundsToBuyer(uint256 token) internal {

        require(Exchanges[token].status == 4);
        require(!Exchanges[token].paid);
        Exchanges[token].paid = true;
        Exchanges[token].buy.transfer(Exchanges[token].amount);
        Exchanges[token].sell.transfer((Sellers[Exchanges[token].sell].rate*(Exchanges[token].amount/1000))*1 finney);
        Exchanges[token].arbit.transfer((((Arbitrator[Exchanges[token].arbit].fee))/1000)*1 finney);
        if(Sellers[Exchanges[token].sell].HighestSold < Exchanges[token].amount) {
            Sellers[Exchanges[token].sell].HighestSold = Exchanges[token].amount;
        }
        Arbitrator[Exchanges[token].arbit].rating++;
        Arbitrator[Exchanges[token].arbit].percentMediated = (Arbitrator[Exchanges[token].arbit].mediatedRating/Arbitrator[Exchanges[token].arbit].rating)*100;
        deleteExchange(token);
    }

    //1st stage of transaction gone wrong. One party reports a fraud. Sets stage to 0, making it impossible for either buyer or Sellers
    //to use any functions relating to the transaction.
    function reportFraud(uint256 _token) external {
        require(checkExchangeRegistry(_token));
        require(msg.sender == Exchanges[_token].buy || msg.sender == Exchanges[_token].sell);
        Exchanges[_token].buysign = true;
        Exchanges[_token].sellsign = true;
        Exchanges[_token].status = 0;
    }

    //2nd stage of transaction gone wrong. Arbitrator checks in. On the front end, this will allow them to view transaction data.
    function arbitrate(uint256 _token) external {
        require(checkExchangeRegistry(_token));
        require(Exchanges[_token].status == 0);
        require(msg.sender == Exchanges[_token].arbit);
        Exchanges[_token].status = 5;
        Exchanges[_token].timecreated = now;
    }

    //3rd stage. Arbitrator decides the buyer/seller is right and the money is paid accordingly.
    function decideBuyer(uint256 _token) external {
        require(checkExchangeRegistry(_token));
        require(msg.sender == Exchanges[_token].arbit);
        require(Exchanges[_token].status == 5);
        require(Exchanges[_token].timecreated == Exchanges[_token].timecreated + 1 days);
        Exchanges[_token].buy.transfer(Exchanges[_token].amount);
        Exchanges[_token].arbit.transfer(Arbitrator[Exchanges[_token].arbit].fee*1 finney);
        deleteExchange(_token);

    }

    //3rd stage. Arbitrator decides the buyer/seller is right and the money is paid accordingly.
    function decideSeller(uint256 _token) external {
        require(checkExchangeRegistry(_token));
        require(msg.sender == Exchanges[_token].arbit);
        require(Exchanges[_token].status == 5);
        require(Exchanges[_token].timecreated == Exchanges[_token].timecreated + 1 days);
        Exchanges[_token].sell.transfer(Exchanges[_token].amount+(Sellers[Exchanges[_token].sell].rate*(Exchanges[_token].amount/1000)*1 finney));
        Exchanges[_token].arbit.transfer(Arbitrator[Exchanges[_token].arbit].fee*1 finney);
        deleteExchange(_token);
    }

    //control function for require statements
    function checkExchangeRegistry(uint256 token) internal view returns(bool) {
        bool check = false;
        for(uint256 i = 0; i < tokens.length; i++) {
            if(tokens[i] == token) {
                check = false;
            }
        }
        return check;
    }

    //allows deletion of exchanges.
    function deleteExchange(uint256 token) internal {
        delete tokens[token];
        for(uint256 i = token; i < tokens.length;i++) {
            tokens[i] = tokens[i + 1];
        }
    }
    //ends here(**)

    //standard owner functions to allow us to profit as well
    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
    //constructor pushes a value for SellList, dims us as Owner, and sets count to 0 for the tokens
    constructor() internal {
        count = 0;
        owner = msg.sender;
        SellList.push(msg.sender);
    }
}
