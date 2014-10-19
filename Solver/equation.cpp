#include <iostream>
#include <stack>
#include <string>
#include <vector>
#include <cmath>

void pop_all_ops(std::vector<double>& postfix, std::stack<char>& ops) {
  char op;
  double num1, num2;

  while(!ops.empty()) {
    op = ops.top();
    ops.pop();
    num2 = postfix.back();
    postfix.pop_back();
    num1 = postfix.back();
    postfix.pop_back();

    if(op == '+') {
      postfix.push_back(num1 + num2);
    } else if(op == '-') {
      postfix.push_back(num1 - num2);
    } else if(op == '*') {
      postfix.push_back(num1 * num2);
    } else if(op == '/') {
      postfix.push_back(num1 / num2);
    } else if(op == '^') {
      postfix.push_back(pow(num1, num2));
    } else {
      throw -1;
    }
  }
}

double expression(std::string a) {
  std::vector<double> postfix;
  std::stack<char> ops;

  int parens;

  postfix.push_back(0);

  for(int i = 0; i < a.length(); ++i) {
    if(a[i] == ' ') {
      continue;
    } else if(a[i] == '(') {
      parens = 0;
      std::string sub = "";
      ++i;

      while(!(a[i] == ')' && parens == 0)) {
        if(a[i] == '(') {
          ++parens;
        } else if(a[i] == ')') {
          --parens;
        }

        sub += a[i];
        ++i;
      }
      
      postfix.pop_back();
      postfix.push_back(expression(sub));
    } else if(a[i] >= '0' && a[i] <= '9') {
      postfix[postfix.size() - 1] *= 10;
      postfix[postfix.size() - 1] += a[i] - '0';
    } else {
      if(((a[i] == '+' || a[i] == '-') && !ops.empty() &&
         (ops.top() == '*' || ops.top() == '/' || ops.top() == '^')) ||
         ((a[i] == '*' || a[i] == '/') && !ops.empty() &&
         ops.top() == '^')) {
        pop_all_ops(postfix, ops);
      }

      ops.push(a[i]);
      postfix.push_back(0);
    }
  }

  pop_all_ops(postfix, ops);

  return postfix.back();
}

int main(int argc, char **argv) {
  // make the big switch statement here
  std::cout << expression(argv[1]) << std::endl;
}
