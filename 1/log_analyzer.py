import re
from datetime import datetime
import sys
from collections import defaultdict

class NginxLogAnalyzer:
    def __init__(self):
        self.log_pattern = re.compile(
            r'(?P<ip>\d+\.\d+\.\d+\.\d+) - - \[(?P<date>.*?)\] '
            r'"(?P<method>\w+) (?P<url>.*?) HTTP/(?P<http_version>[\d.]+)" '
            r'(?P<status>\d+) (?P<size>\d+) '
            r'"(?P<referer>.*?)" "(?P<user_agent>.*?)" '
            r'"(?P<response_time>[\d.]+)"'
        )
        
    def parse_log_line(self, line):
        """解析单行日志"""
        match = self.log_pattern.match(line)
        if match:
            return match.groupdict()
        return None
    
    def analyze_logs(self, log_file_path, target_date):
        """分析日志文件"""
        
        https_domain1_count = 0
        daily_requests = 0
        daily_success_count = 0
        
        print(f"开始分析日志文件: {log_file_path}")
        print(f"目标日期: {target_date}")
        print("-" * 50)
        
        try:
            with open(log_file_path, 'r', encoding='utf-8') as file:
                for line_num, line in enumerate(file, 1):
                    
                    if line_num % 1000000 == 0:
                        print(f"已处理 {line_num} 行...")
                    
                    parsed = self.parse_log_line(line.strip())
                    if not parsed:
                        continue
                    
                    log_date = parsed['date'].split(':')[0]
                    
                    # 统计HTTPS请求中以domain1.com为域名的数量
                    referer = parsed['referer']
                    if referer != '-':
                        if referer.startswith('https://domain1.com') or \
                           'https://domain1.com/' in referer:
                            https_domain1_count += 1
                    
                    # 统计目标日期的请求
                    if log_date == target_date:
                        daily_requests += 1
                        status_code = int(parsed['status'])
                        # 判断是否为成功请求
                        if 200 <= status_code < 300:
                            daily_success_count += 1
            
            success_ratio = 0
            if daily_requests > 0:
                success_ratio = (daily_success_count / daily_requests) * 100
            
            return {
                'total_lines_processed': line_num,
                'https_domain1_count': https_domain1_count,
                'daily_requests': daily_requests,
                'daily_success_count': daily_success_count,
                'success_ratio': success_ratio
            }
            
        except FileNotFoundError:
            print(f"错误: 找不到文件 {log_file_path}")
            return None
        except Exception as e:
            print(f"处理文件时发生错误: {e}")
            return None

def main():
    if len(sys.argv) != 3:
        print("用法: python log_analyzer.py <日志文件路径> <目标日期>")
        print("示例: python log_analyzer.py access.log '28/Feb/2019'")
        sys.exit(1)
    
    log_file = sys.argv[1]
    target_date = sys.argv[2]
    
    try:
        datetime.strptime(target_date, '%d/%b/%Y')
    except ValueError:
        print("错误: 日期格式不正确，请使用 '28/Feb/2019' 格式")
        sys.exit(1)
    
    analyzer = NginxLogAnalyzer()
    results = analyzer.analyze_logs(log_file, target_date)
    
    if results:
        print("\n" + "="*50)
        print("分析结果:")
        print("="*50)
        print(f"处理的总行数: {results['total_lines_processed']:,}")
        print(f"HTTPS请求中以 domain1.com 为域名的数量: {results['https_domain1_count']:,}")
        print(f"目标日期 {target_date} 的总请求数: {results['daily_requests']:,}")
        print(f"目标日期 {target_date} 的成功请求数: {results['daily_success_count']:,}")
        print(f"成功请求比例: {results['success_ratio']:.2f}%")
        
        with open('analysis_results.txt', 'w') as f:
            f.write("Nginx日志分析结果\\n")
            f.write("="*30 + "\\n")
            f.write(f"分析时间: {datetime.now()}\\n")
            f.write(f"日志文件: {log_file}\\n")
            f.write(f"目标日期: {target_date}\\n\\n")
            f.write(f"处理的总行数: {results['total_lines_processed']:,}\\n")
            f.write(f"HTTPS请求中以 domain1.com 为域名的数量: {results['https_domain1_count']:,}\\n")
            f.write(f"目标日期总请求数: {results['daily_requests']:,}\\n")
            f.write(f"目标日期成功请求数: {results['daily_success_count']:,}\\n")
            f.write(f"成功请求比例: {results['success_ratio']:.2f}%\\n")

if __name__ == "__main__":
    main()
