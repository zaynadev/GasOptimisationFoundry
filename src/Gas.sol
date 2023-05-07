// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Ownable.sol";

contract GasContract is Ownable {
    uint256 public immutable totalSupply; // cannot be updated
    uint256 public paymentCounter;
    mapping(address => uint256) public balances;
    address public contractOwner;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    History[] public paymentHistory; // when a payment was updated

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }
    uint256 wasLastOdd = 1;
    mapping(address => uint256) public isOddWhitelistUser;

    struct ImportantStruct {
        uint256 amount;
        uint256 bigValue;
        address sender;
        uint16 valueB; // max 3 digits
        uint16 valueA; // max 3 digits
        bool paymentStatus;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    error OnlyForAdminOrOwner();
    error OnlyForWhiteListed();
    error InsufficientBalance();
    error RecipientNameTooLong();
    error ZeroID();
    error ZeroAddress();
    error ErrorTierValue();
    error ContractHacked();
    error AmountSouldBeBiggerThan_3();

    function checkForAdmin(address _user) private view returns (bool) {
        unchecked {
            for (uint256 ii = 0; ii < 5; ++ii) {
                if (administrators[ii] == _user) {
                    return true;
                }
            }
        }
        return false;
    }

    modifier onlyAdminOrOwner() {
        if (contractOwner != msg.sender || !checkForAdmin(msg.sender)) {
            revert OnlyForAdminOrOwner();
        }
        _;
    }

    modifier checkIfWhiteListed(address sender) {
        uint256 usersTier = whitelist[msg.sender];
        if (sender != msg.sender && usersTier < 4) {
            revert OnlyForWhiteListed();
        }
        _;
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;
        unchecked {
            for (uint256 ii = 0; ii < 5; ++ii) {
                if (_admins[ii] != address(0)) {
                    administrators[ii] = _admins[ii];
                    if (_admins[ii] == contractOwner) {
                        balances[contractOwner] = totalSupply;
                        emit supplyChanged(_admins[ii], totalSupply);
                    }
                }
            }
        }
    }

    function getPaymentHistory()
        public
        payable
        returns (History[] memory paymentHistory_)
    {
        return paymentHistory;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function getTradingMode() public pure returns (bool) {
        return true;
    }

    function addHistory(address _updateAddress, bool _tradeMode) internal {
        paymentHistory.push(
            History(block.timestamp, _updateAddress, block.number)
        );
    }

    function getPayments(
        address _user
    ) public view returns (Payment[] memory payments_) {
        return payments[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) external {
        if (balances[msg.sender] < _amount) {
            revert InsufficientBalance();
        }
        if (bytes(_name).length >= 9) {
            revert RecipientNameTooLong();
        }

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;

        payments[msg.sender].push(
            Payment(
                PaymentType.BasicPayment,
                ++paymentCounter,
                false,
                _name,
                _recipient,
                address(0),
                _amount
            )
        );
        emit Transfer(_recipient, _amount);
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) external onlyAdminOrOwner {
        if (_ID == 0) {
            revert ZeroID();
        }
        if (_amount <= 0) {
            revert InsufficientBalance();
        }
        if (_user == address(0)) {
            revert ZeroAddress();
        }

        Payment[] storage payment = payments[_user];
        Payment[] memory _payment = payments[_user];

        for (uint256 ii = 0; ii < _payment.length; ii++) {
            if (_payment[ii].paymentID == _ID) {
                payment[ii].adminUpdated = true;
                payment[ii].admin = _user;
                payment[ii].paymentType = _type;
                payment[ii].amount = _amount;
                bool tradingMode = getTradingMode();
                addHistory(_user, tradingMode);
                emit PaymentUpdated(
                    msg.sender,
                    _ID,
                    _amount,
                    _payment[ii].recipientName
                );
            }
        }
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) external onlyAdminOrOwner {
        if (_tier >= 255) {
            revert ErrorTierValue();
        }

        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else {
            whitelist[_userAddrs] = _tier;
        }

        uint256 wasLastAddedOdd = wasLastOdd;
        if (wasLastAddedOdd == 1) {
            wasLastOdd = 0;
            isOddWhitelistUser[_userAddrs] = 1;
        } else if (wasLastAddedOdd == 0) {
            wasLastOdd = 1;
            isOddWhitelistUser[_userAddrs] = 0;
        } else {
            revert ContractHacked();
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) external checkIfWhiteListed(msg.sender) {
        whiteListStruct[msg.sender] = ImportantStruct(
            _amount,
            0,
            msg.sender,
            0,
            0,
            true
        );
        uint balanceSender = balances[msg.sender];
        uint balanceRecipient = balances[_recipient];

        if (balanceSender < _amount) {
            revert InsufficientBalance();
        }

        if (_amount <= 3) {
            revert AmountSouldBeBiggerThan_3();
        }

        balances[msg.sender] =
            (balanceSender - _amount) +
            whitelist[msg.sender];
        balances[_recipient] =
            (balanceRecipient + _amount) -
            whitelist[msg.sender];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (
            whiteListStruct[sender].paymentStatus,
            whiteListStruct[sender].amount
        );
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
