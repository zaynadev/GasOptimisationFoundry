// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./IGasContract.sol";

contract Constants {
    uint256 public tradeFlag = 1;
    uint256 public basicFlag = 0;
    uint256 public dividendFlag = 1;                        
}

contract GasContract is IGasContract, Ownable, Constants {
    uint256 public totalSupply;
    uint256 public paymentCounter;
    
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) whitelist;
    mapping(address => uint256) public balances;
    mapping(address => ImportantStruct) public whiteListStruct;

    // Sorted
    mapping (address => bool) private isAdmin;

    PaymentType constant defaultPayment = PaymentType.Unknown;

    History[] public paymentHistory;

    modifier compareBalance(address _user, uint _amount) {
        uint balance_ = balances[senderOfTx];
        if(balance_ < _amount) { revert InsufficientBalance(balance_) };
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = _msgSender();
        totalSupply = _totalSupply;
        balances[contractOwner] = totalSupply;
        wasLastOdd = 1;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            address currentAddr = _admins[ii];
            if (currentAddr != address(0)) {
                isAdmin[currentAddr] = true;
            }
        }
        emit supplyChanged(contractOwner, totalSupply);
    }

    receive() external payable {
        revert();
    }


    fallback() external payable {
        revert();
    }

    function _onlyAdminOrOwner() internal returns(address senderOfTx) {
        senderOfTx = _msgSender();
        require(_user == owner() || _checkForAdmin(senderOfTx), "Access denied");
        return senderOfTx;
    }

    function _checkIfWhiteListed() internal {
        uint256 usersTier = whitelist[_msgSender()];
        require(usersTier > 0 && userTier < 4, "GC: Not whitelisted");
    }

    function getPaymentHistory()
        public
        payable
        returns (History[] memory paymentHistory_)
    {
        return paymentHistory;
    }

    /// @dev Function activates or deactivates admin
    function setAdmin(address _user, bool _status) public onlyOwner {
        bool _isAdmin = isAdmin[_user];
        if(!_isAdmin) {
            if(!_status) revert TargetAlreadyAnAdmin(_user);
        } else {
            if(_status) revert TargetAlreadyDeactivated(_user);
        }
        isAdmin[_user] = _status;
    }

    function _checkForAdmin(address _user) public view returns (bool admin_) {
        _admin = isAdmin[_user];
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        balance_ = balances[_user];
        return balance_;
    }

    function getTradingMode() public view returns (bool) {
        if (tradeFlag == 1 || dividendFlag == 1) {
            return true;
        }
        return false;
    }

    function addHistory(address _updateAddress, bool _tradeMode) public
    {
        paymentHistory.push(History(block.timestamp, _updateAddress, block.number));
    }

    function getPayments(address _user)
        public
        view
        returns (Payment[] memory)
    {
        if(_user == address(0)) revert InvalidAddress();
        return payments[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public compareBalance(_recipient, _amount) returns (bool) {
        address senderOfTx = _msgSender();
        uint balance_ = balances[senderOfTx];
        uint nameLen = bytes(_name).length;
        if(nameLen > 8) revert MaxNameLengthExceeded(nameLen);

        balances[senderOfTx] = balance_ - _amount;
        balances[_recipient] += _amount;

        emit Transfer(_recipient, _amount);
        payments[senderOfTx].push(
            Payment(
                PaymentType.BasicPayment,
                _getPaymentCounter(),
                false,
                _name,
                _recipient,
                address(0),
                _amount
            )
        );

        return true;
    }

    function _getPaymentCounter() internal returns(uint counter) {
        paymentCounter ++;
        counter = paymentCounter;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public {
        address senderOfTx = _onlyAdminOrOwner();
        if(amount == 0) revert AmountShouldBeGreaterThanZero();
        if(_user == address(0)) revert InvalidAddress(_user);

        require(payments[_user].length > _ID, "Invalid ID");
        payments[_user][_ID].adminUpdated = true;
        payments[_user][_ID].admin = _user;
        payments[_user][_ID].paymentType = _type;
        payments[_user][_ID].amount = _amount;
        bool tradingMode = getTradingMode();
        addHistory(_user, tradingMode);
        emit PaymentUpdated(
            senderOfTx,
            _ID,
            _amount,
            payments[_user][_ID].recipientName
        );
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public
    {
        _onlyAdminOrOwner();
        if(tier > type(uint8).max) revert LevelExceedBoundry(_tier);
        whitelist[_userAddrs] = _tier;

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public compareBalance(_recipient, _amount) {
        _checkIfWhiteListed();
        address senderOfTx = _msgSender();
        whiteListStruct[senderOfTx] = ImportantStruct(_amount, 0, 0, 0, true, senderOfTx);
        if(_amount <= 3) revert AmountShouldBeAbove3(_amount);
        uint w_balanceSender = whitelist[senderOfTx];
        uint w_balanceRecipient = whitelist[recipient];
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += w_balanceSender
        balances[_recipient] -= w_balanceRecipient;
        
        emit WhiteListTransfer(_recipient);
    }


    function getPaymentStatus(address sender) public returns (bool, uint256) {        
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }
}