#include <iostream>
#include <stack>
#include <string>
#include <vector>
#include <cmath>
#include <algorithm>

using namespace std;

string pop_all_ops(vector<double>& postfix, stack<char>& ops) {
  char op;
  double num1, num2;
  string steps = "";
  char buffer[128];

  // Pop all the operations off the ops stack, and push the result onto the
  // postfix vector.
  while(!ops.empty()) {
    op = ops.top();
    ops.pop();

    num2 = postfix.back();
    postfix.pop_back();
    num1 = postfix.back();
    postfix.pop_back();

    if(op == '+') {
      postfix.push_back(num1 + num2);
    }
    else if(op == '-') {
      postfix.push_back(num1 - num2);
    }
    else if(op == '*') {
      postfix.push_back(num1 * num2);
    }
    else if(op == '/') {
      postfix.push_back(num1 / num2);
    }
    else if(op == '^') {
      postfix.push_back(pow(num1, num2));
    }
    else {
      throw -1;
    }

    // Add the step we just took to the steps string.
    sprintf(buffer, "%g %c %g = %g\n", num1, op, num2, postfix.back());
    steps += string(buffer);
  }

  return steps;
}

pair<double, string> expression(string a) {
  vector<double> postfix;
  stack<char> ops;
  stack<char> trig;
  pair<double, string> temp_pair;
  string result = "";

  // Remove all whitespace from the input string.
  a.erase(remove_if(a.begin(), a.end(), (int(*)(int))isspace), a.end());
  int parens;

  postfix.push_back(0);

  for(int i = 0; i < a.length(); ++i) {
    // If we encounter an open parentheses, move through the string until we
    // find the matching closing parentheses. Recursively call expression()
    // on the substring and add the result to the postfix vector.
    if(a[i] == 'c' || a[i] == 's' || a[i] == 't'){
      trig.push(a[i]);
    }
    else if(a[i] == '(') {
      parens = 0;
      string sub = "";
      ++i;

      while(!(a[i] == ')' && parens == 0)) {
        if(a[i] == '(') {
          ++parens;
        }
        else if(a[i] == ')') {
          --parens;
        }

        sub += a[i];
        ++i;
      }

      temp_pair = expression(sub);
      if(!trig.empty()){
        char trigFun = trig.top();
        if(trigFun == 'c'){
          postfix.pop_back();
          postfix.push_back(cos(temp_pair.first));
        }
        else if(trigFun == 's'){
          postfix.pop_back();
          postfix.push_back(sin(temp_pair.first));
        }
        else if(trigFun == 't'){
          postfix.pop_back();
          postfix.push_back(tan(temp_pair.first));
        }
      }
      else{
        postfix.pop_back();
        postfix.push_back(temp_pair.first);
      }



      result += temp_pair.second;
    }
    // New digit to add.
    else if(a[i] >= '0' && a[i] <= '9') {
      postfix[postfix.size() - 1] *= 10;
      postfix[postfix.size() - 1] += a[i] - '0';
    }
    // If we encounter a negative sign and the character immediately preceding
    // it is not a number, we know that this minus sign is intended identify
    // the following number as negative.
    else if((a[i] == '-' && i == 0) ||
            (a[i] == '-' && i > 0 &&
            (a[i - 1] <= '0' || a[i - 1] >= '9'))) {
      ops.push('*');

      postfix.pop_back();
      postfix.push_back(-1);
      postfix.push_back(0);
    }
    // If the operator we encounter has lower precedence than the operator
    // on the top of the stack, we need pop all the operators off the stack
    // and change the postfix vector to a single result.
    else {
      if(((a[i] == '+' || a[i] == '-') && !ops.empty() &&
         (ops.top() == '*' || ops.top() == '/' || ops.top() == '^')) ||
         ((a[i] == '*' || a[i] == '/') && !ops.empty() &&
         ops.top() == '^')) {
        result += pop_all_ops(postfix, ops);
      }

      ops.push(a[i]);

      postfix.push_back(0);
    }
  }

  result += pop_all_ops(postfix, ops);

  return make_pair(postfix.back(), result);
}

int main() {
  // make the big switch statement here
  string input;

  while(true) {
    getline(cin, input);
    if(!cin) {
      break;
    }

    cout << expression(input).second << endl;
    cout << "Result: " << expression(input).first << endl << endl;
  }

  return 0;
}
