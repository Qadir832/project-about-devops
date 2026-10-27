
const display = document.querySelector("#display");
const message = document.querySelector("#message");
const buttons = document.querySelector(".buttons");

let current = "0";
let firstOperand = null;
let operator = null;
let waitingForSecond = false;
let hasError = false;

function render() {
    display.textContent = current;
}

function showMessage(text = "") {
    message.textContent = text;
}

function reset() {
    current = "0";
    firstOperand = null;
    operator = null;
    waitingForSecond = false;
    hasError = false;

    showMessage();
    render();
}

function enterDigit(digit) {
    if (hasError) reset();

    if (waitingForSecond) {
        current = digit;
        waitingForSecond = false;
    } else if (current === "0") {
        current = digit;
    } else if (current.length < 15) {
        current += digit;
    }

    showMessage();
    render();
}

function enterDecimal() {
    if (hasError) reset();

    if (waitingForSecond) {
        current = "0.";
        waitingForSecond = false;
    } else if (!current.includes(".")) {
        current += ".";
    }

    showMessage();
    render();
}

function calculate(a, b, op) {
    switch (op) {
        case "+":
            return a + b;
        case "-":
            return a - b;
        case "*":
            return a * b;
        case "/":
            return b === 0 ? null : a / b;
        default:
            return null;
    }
}

function formatResult(result) {
    if (!Number.isFinite(result)) return null;

    const rounded = Number(result.toPrecision(12));

    return String(Object.is(rounded, -0) ? 0 : rounded);
}

function chooseOperator(nextOperator) {
    if (hasError) reset();

    const inputValue = Number(current);

    if (operator && !waitingForSecond) {
        const result = calculate(
            firstOperand,
            inputValue,
            operator
        );

        const formatted = result === null
            ? null
            : formatResult(result);

        if (formatted === null) {
            current = "Error";
            hasError = true;
            showMessage("Cannot divide by zero or calculate this result.");
            render();
            return;
        }

        current = formatted;
        firstOperand = Number(formatted);
    } else if (firstOperand === null || !operator) {
        firstOperand = inputValue;
    }

    operator = nextOperator;
    waitingForSecond = true;

    showMessage();
    render();
}

function equals() {
    if (!operator || waitingForSecond || hasError) return;

    const result = calculate(
        firstOperand,
        Number(current),
        operator
    );

    const formatted = result === null
        ? null
        : formatResult(result);

    if (formatted === null) {
        current = "Error";
        hasError = true;
        showMessage("Cannot divide by zero or calculate this result.");
    } else {
        current = formatted;
        showMessage();
    }

    firstOperand = null;
    operator = null;
    waitingForSecond = true;

    render();
}

function deleteLast() {
    if (hasError) {
        reset();
        return;
    }

    if (waitingForSecond) return;

    current = current.length > 1
        ? current.slice(0, -1)
        : "0";

    if (current === "-" || current === "") {
        current = "0";
    }

    render();
}

buttons.addEventListener("click", (event) => {
    const button = event.target.closest("button");

    if (!button) return;

    if (button.dataset.digit !== undefined) {
        enterDigit(button.dataset.digit);
        return;
    }

    if (button.dataset.operator) {
        chooseOperator(button.dataset.operator);
        return;
    }

    switch (button.dataset.action) {
        case "clear":
            reset();
            break;
        case "delete":
            deleteLast();
            break;
        case "decimal":
            enterDecimal();
            break;
        case "equals":
            equals();
            break;
    }
});

document.addEventListener("keydown", (event) => {
    if (/^[0-9]$/.test(event.key)) {
        enterDigit(event.key);
    } else if (event.key === ".") {
        enterDecimal();
    } else if (["+", "-", "*", "/"].includes(event.key)) {
        chooseOperator(event.key);
    } else if (event.key === "Enter" || event.key === "=") {
        event.preventDefault();
        equals();
    } else if (event.key === "Backspace") {
        deleteLast();
    } else if (event.key === "Escape") {
        reset();
    }
});

render();
